const { contract, accounts, web3 } = require('@openzeppelin/test-environment')
const { time, balance, expectRevert } = require('@openzeppelin/test-helpers')
const { trackBalance, ether, safeBN, ZERO } = require('./utils')(web3)
const { expect } = require('chai')
const [admin, employer, contractor, attacker] = accounts
const { rulings } = require('../helpers')

const WorkAgreement = contract.fromArtifact('WorkAgreement')
const TestERC20 = contract.fromArtifact('TestERC20')
const MockArbitrator = contract.fromArtifact('MockArbitrator')
const MockManifest = contract.fromArtifact('MockManifest')

describe('WorkAgreement', () => {
  const setupMockEnv = async () => {
    this.token = await TestERC20.new({ from: admin })
    this.arbitrator = await MockArbitrator.new(this.token.address, { from: admin })
    this.manifest = await MockManifest.new(this.arbitrator.address, { from: admin })
  }

  const initAgreement = async () => {
    this.agreementDuration = time.duration.days(31)
    this.releaseTime = (await time.latest()).add(this.agreementDuration)
    this.agreementSalt = '0xb70bfecd623063460c559c121a8033e5b47edc1a523f967bf19ccc3c61dd5178'
    this.agreementText = web3.utils.asciiToHex(
      'Some placeholder text. (invalid by Celeste\'s metadata standard)'
    )
    this.agreementCommitment = web3.utils.keccak256(
      web3.eth.abi.encodeParameters(['bytes32', 'bytes'], [this.agreementSalt, this.agreementText])
    )
    this.escrowAmount = ether('4')
    this.agreement = await WorkAgreement.new(
      this.arbitrator.address,
      this.manifest.address,
      this.agreementCommitment,
      this.releaseTime,
      contractor,
      { from: employer, value: this.escrowAmount }
    )
  }

  const triggerDispute = async () => {
    const { feeAmount } = await this.arbitrator.getDisputeFees()
    await this.token.mint(employer, feeAmount, { from: admin })
    await this.token.approve(this.agreement.address, feeAmount, { from: employer })
    await this.agreement.dispute(this.agreementSalt, this.agreementText, {
      from: employer
    })
    return await this.agreement.disputeId()
  }

  describe('undisputed release', () => {
    before(async () => {
      await setupMockEnv()
      await initAgreement()
    })
    it('agreement holds funds', async () => {
      expect(await balance.current(this.agreement.address)).to.be.bignumber.equal(this.escrowAmount)
    })
    it('disallows payment release before release time', async () => {
      await expectRevert(
        this.agreement.releasePayment({ from: contractor }),
        'WorkAgreement: not yet unlocked'
      )
    })
    it('cannot release payment if not contractor', async () => {
      await expectRevert(
        this.agreement.releasePayment({ from: attacker }),
        'WorkAgreement: not contractor'
      )
    })
    it('disallows disputing release after release time has passed', async () => {
      await time.increaseTo(this.releaseTime)
      await expectRevert(
        this.agreement.dispute(this.agreementSalt, this.agreementText, { from: employer }),
        'WorkAgreement: already unlocked'
      )
    })
    it('allows release of payment after time has passed', async () => {
      const contractorBalTracker = await trackBalance(null, contractor)
      const { receipt } = await this.agreement.releasePayment({ from: contractor })
      const { gasPrice } = await web3.eth.getTransaction(receipt.transactionHash)
      const txFee = safeBN(receipt.gasUsed).mul(safeBN(gasPrice))
      expect(await contractorBalTracker.delta()).to.be.bignumber.equal(
        this.escrowAmount.sub(safeBN(txFee))
      )
    })
  })
  describe('disputed release', () => {
    before(async () => {
      await setupMockEnv()
      await initAgreement()
    })
    it('disallows non-employer from initiating dispute', async () => {
      await expectRevert(
        this.agreement.dispute(this.agreementSalt, this.agreementText, { from: attacker }),
        'WorkAgreement: not employer'
      )
      await expectRevert(
        this.agreement.dispute(this.agreementSalt, this.agreementText, { from: contractor }),
        'WorkAgreement: not employer'
      )
    })
    it('allows employer to initiate dispute', async () => {
      this.disputeId = await triggerDispute()
      expect(this.disputeId).to.be.bignumber.equal(safeBN(0))
      expect(await this.arbitrator.getSubjectOf(this.disputeId)).to.equal(this.agreement.address)
      expect(await this.agreement.beingDisputed()).to.be.true
    })
    it('disallows payment release while being disputed', async () => {
      await time.increaseTo(this.releaseTime)
      await expectRevert(
        this.agreement.releasePayment({ from: contractor }),
        'WorkAgreement: being disputed'
      )
    })
    it('disallows settling dispute without ruling', async () => {
      await expectRevert(this.agreement.settleDispute(), 'DM_INVALID_ADJUDICATION_STATE')
    })
    it('allows settlement once ruling is present', async () => {
      await this.arbitrator.setRuling(this.disputeId, rulings.REFUSED, { from: admin })
      await this.agreement.settleDispute()
    })
  })
  describe('settlement outcome based on ruling', () => {
    beforeEach(async () => {
      await setupMockEnv()
      await initAgreement()
      this.disputeId = await triggerDispute()
      this.balances = {
        contractor: await trackBalance(null, contractor),
        employer: await trackBalance(null, employer)
      }
    })
    it('credits payment to contractor if ruling is for action', async () => {
      await this.arbitrator.setRuling(this.disputeId, rulings.FOR_ACTION, { from: admin })
      await this.agreement.settleDispute()
      expect(await this.balances.contractor.delta()).to.be.bignumber.equal(this.escrowAmount)
      expect(await this.balances.employer.delta()).to.be.bignumber.equal(ZERO)
    })
    it('credits payment to contractor if ruling is refused', async () => {
      await this.arbitrator.setRuling(this.disputeId, rulings.REFUSED, { from: admin })
      await this.agreement.settleDispute()
      expect(await this.balances.contractor.delta()).to.be.bignumber.equal(this.escrowAmount)
      expect(await this.balances.employer.delta()).to.be.bignumber.equal(ZERO)
    })
    it('credits payment to employer when ruling is against action', async () => {
      await this.arbitrator.setRuling(this.disputeId, rulings.AGAINST_ACTION, { from: admin })
      await this.agreement.settleDispute()
      expect(await this.balances.employer.delta()).to.be.bignumber.equal(this.escrowAmount)
      expect(await this.balances.contractor.delta()).to.be.bignumber.equal(ZERO)
    })
  })
})
