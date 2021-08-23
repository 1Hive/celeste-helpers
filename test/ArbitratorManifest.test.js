const { contract, accounts, web3 } = require('@openzeppelin/test-environment')
const { constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
const { ether, safeBN } = require('./utils')(web3)
const { expect } = require('chai')

const [admin, user1, user2, rep1, attacker1, attacker2] = accounts

const TestERC20 = contract.fromArtifact('TestERC20')
const MockArbitrator = contract.fromArtifact('MockArbitrator')
const MockManifest = contract.fromArtifact('MockManifest')
const SimpleDisputable = contract.fromArtifact('SimpleDisputable')

describe('ArbitratorManifest', () => {
  const checkCanSubmitEvidence = (canSubmitRes, onBehalfOf) => {
    if (onBehalfOf === null) {
      expect(canSubmitRes[0]).to.be.false
      expect(canSubmitRes[1]).to.equal(constants.ZERO_ADDRESS)
    } else {
      expect(canSubmitRes[0]).to.be.true
      expect(canSubmitRes[1]).to.equal(onBehalfOf)
    }
  }

  before(async () => {
    this.token = await TestERC20.new({ from: admin })
    this.arbitrator = await MockArbitrator.new(this.token.address, { from: admin })
    this.manifest = await MockManifest.new(this.arbitrator.address, { from: admin })
    this.disputable = await SimpleDisputable.new(this.arbitrator.address, this.manifest.address)

    await this.token.mint(user1, ether('1000'), { from: admin })
    await this.token.approve(this.disputable.address, constants.MAX_UINT256, { from: user1 })
  })
  it('correct initial values', async () => {
    expect(await this.manifest.disputeManager()).to.equal(await this.arbitrator.getDisputeManager())
    expect(await this.manifest.isRepOf(user1, user2)).to.be.false
    expect(await this.manifest.isRepOf(user2, user1)).to.be.false
    expect(await this.manifest.canRepresent(user1, user2)).to.be.false
    expect(await this.manifest.canRepresent(user2, user1)).to.be.false
    expect(await this.manifest.defendantOf(safeBN(3))).to.equal(constants.ZERO_ADDRESS)
    expect(await this.manifest.challengerOf(safeBN(3))).to.equal(constants.ZERO_ADDRESS)
  })
  it('only allows subject to set parties', async () => {
    await this.disputable.createDispute('0x', { from: user1 })
    const disputeId = safeBN(0)
    await expectRevert(
      this.manifest.setPartiesOf(disputeId, attacker1, attacker2, { from: attacker1 }),
      'ArbManifest: not subject'
    )
    const receipt = await this.disputable.setPartiesOf(disputeId, user1, user2, { from: attacker1 })
    expectEvent.inTransaction(receipt.tx, this.manifest, 'PartiesSet', {
      disputeId,
      defendant: user1,
      challenger: user2
    })
    expect(await this.manifest.defendantOf(disputeId)).to.equal(user1)
    expect(await this.manifest.challengerOf(disputeId)).to.equal(user2)
  })
  it('can override parties', async () => {
    const disputeId = safeBN(0)
    const receipt = await this.disputable.setPartiesOf(disputeId, user2, user1)
    expectEvent.inTransaction(receipt.tx, this.manifest, 'PartiesSet', {
      disputeId,
      defendant: user2,
      challenger: user1
    })
    expect(await this.manifest.defendantOf(disputeId)).to.equal(user2)
    expect(await this.manifest.challengerOf(disputeId)).to.equal(user1)

    await this.disputable.setPartiesOf(disputeId, user1, user2)
  })
  it('allows direct dispute parties to submit evidence', async () => {
    const disputeId = safeBN(0)

    const res1 = await this.manifest.canSubmitEvidenceFor(user1, disputeId)
    expect(res1[0]).to.be.true // canSubmit
    expect(res1[1]).to.equal(user1)

    const res2 = await this.manifest.canSubmitEvidenceFor(user2, disputeId)
    expect(res2[0]).to.be.true // canSubmit
    expect(res2[1]).to.equal(user2)
  })
  it('disallows other parties from submitting evidence', async () => {
    const disputeId = safeBN(0)
    const res = await this.manifest.canSubmitEvidenceFor(attacker1, disputeId)
    checkCanSubmitEvidence(res, null)
  })
  it('disallows representation by default', async () => {
    await expectRevert(
      this.manifest.setRepStatus(rep1, true, { from: user1 }),
      'ArbManifest: cannot rep'
    )
  })
  it('allows representative to enable representation', async () => {
    const receipt = await this.manifest.allowRepresentation(user1, true, { from: rep1 })
    expectEvent(receipt, 'AllowRepresentation', {
      rep: rep1,
      client: user1,
      allowed: true
    })
    expect(await this.manifest.canRepresent(rep1, user1)).to.be.true
  })
  it('allows client to set enabled representative', async () => {
    const receipt = await this.manifest.setRepStatus(rep1, true, { from: user1 })
    expectEvent(receipt, 'RepStateSet', {
      client: user1,
      rep: rep1,
      isActive: true
    })
    expect(await this.manifest.isRepOf(user1, rep1)).to.be.true
  })
  it('allows representative to submit evidence', async () => {
    const disputeId = safeBN(0)
    const res = await this.manifest.canSubmitEvidenceFor(rep1, disputeId)
    checkCanSubmitEvidence(res, user1)
  })
  it('disallows representative to submit evidence during conflict', async () => {
    await this.manifest.allowRepresentation(user2, true, { from: rep1 })
    await this.manifest.setRepStatus(rep1, true, { from: user2 })

    const disputeId = safeBN(0)
    const res = await this.manifest.canSubmitEvidenceFor(rep1, disputeId)
    checkCanSubmitEvidence(res, null)
  })
  it('allows client to revoke representation', async () => {
    const receipt = await this.manifest.setRepStatus(rep1, false, { from: user2 })
    expectEvent(receipt, 'RepStateSet', {
      client: user2,
      rep: rep1,
      isActive: false
    })
    expect(await this.manifest.isRepOf(user2, rep1)).to.be.false

    const disputeId = safeBN(0)
    const res = await this.manifest.canSubmitEvidenceFor(rep1, disputeId)
    checkCanSubmitEvidence(res, user1)
  })
  it('allows representative to revoke representation', async () => {
    await this.manifest.setRepStatus(rep1, true, { from: user2 })
    expect(await this.manifest.isRepOf(user2, rep1)).to.be.true

    const receipt = await this.manifest.allowRepresentation(user2, false, { from: rep1 })
    expectEvent(receipt, 'AllowRepresentation', {
      rep: rep1,
      client: user2,
      allowed: false
    })
    expect(await this.manifest.canRepresent(rep1, user2)).to.be.false
    expectEvent(receipt, 'RepStateSet', {
      client: user2,
      rep: rep1,
      isActive: false
    })
    expect(await this.manifest.isRepOf(user2, rep1)).to.be.false
  })
  it('disallows defendant and challenger to be same address', async () => {
    const disputeId = safeBN(0)
    await expectRevert(
      this.disputable.setPartiesOf(disputeId, user1, user1),
      'ArbManifest: party conflict'
    )
  })
  it('disallow representative to submit evidence if also opposing party', async () => {
    const disputeId = safeBN(0)
    await this.manifest.allowRepresentation(user2, true, { from: user1 })
    await this.manifest.allowRepresentation(user1, true, { from: user2 })

    await this.manifest.setRepStatus(user1, true, { from: user2 })
    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user1, disputeId), null)
    await this.manifest.setRepStatus(user1, false, { from: user2 })

    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user1, disputeId), user1)
    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user2, disputeId), user2)

    await this.manifest.setRepStatus(user2, true, { from: user1 })
    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user2, disputeId), null)
    await this.manifest.setRepStatus(user2, false, { from: user1 })

    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user1, disputeId), user1)
    checkCanSubmitEvidence(await this.manifest.canSubmitEvidenceFor(user2, disputeId), user2)
  })
})
