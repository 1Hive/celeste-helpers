const { contract, accounts, web3 } = require('@openzeppelin/test-environment')
const { time, balance, expectRevert } = require('@openzeppelin/test-helpers')
const { trackBalance, ether } = require('./utils')(web3)
const { expect } = require('chai')
const [admin1, user1, user2, attacker1] = accounts

const WorkAgreement = contract.fromArtifact('WorkAgreement')
const TestERC20 = contract.fromArtifact('TestERC20')
const MockArbitrator = contract.fromArtifact('MockArbitrator')
const MockManifest = contract.fromArtifact('MockManifest')

describe('WorkAgreement', () => {
  const setupMockEnv = async () => {
    this.token = await TestERC20.new({ from: admin1 })
    this.arbitrator = await MockArbitrator.new(this.token.address, { from: admin1 })
    this.manifest = await MockManifest.new(this.arbitrator.address, { from: admin1 })
  }

  const initAgreement = async () => {
    this.agreementDuration = time.duration.days(31)
    this.releaseTime = (await time.latest()).add(this.agreementDuration)
    this.agreementSalt = web3.utils.randomHex(32)
    this.agreementText = "Some placeholder text. (invalid by Celeste's metadata standard)"
    this.agreementCommitment = web3.utils.soliditySha3(
      {
        type: 'bytes32',
        value: this.agreementSalt
      },
      {
        type: 'bytes',
        value: web3.utils.asciiToHex(this.agreementText)
      }
    )
    this.escrowAmount = ether('4')
    this.agreement = await WorkAgreement.new(
      this.arbitrator.address,
      this.manifest.address,
      this.agreementCommitment,
      this.releaseTime,
      user2,
      { from: user1, value: ether('4') }
    )
    this.balances = {
      user1: await trackBalance(null, user1),
      user2: await trackBalance(null, user2)
    }
  }

  describe('undisputed release', () => {
    before(async () => {
      await setupMockEnv()
      await initAgreement()
    })
    it('agreement holds funds', async () => {
      expect(await balance.current(this.agreement.address)).to.be.bignumber.equal(this.escrowAmount)
    })
    it('cannot release payment if not contractor', async () => {
      await time.increaseTo(this.releaseTime)
      await expectRevert(this.agreement.releasePayment({ from: attacker1 }))
    })
  })
})
