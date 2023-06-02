import { expect } from 'chai'

import { setup } from './tools/setup'
import { ethers } from 'hardhat'
import { keccak256 } from 'ethers/lib/utils'

describe('KycERC20', function () {
  describe('Deployment', function () {
    it('Should deploy KycERC20', async function () {
      const { deployer } = await setup()
      expect(deployer['KycERC20'].address).to.be.properAddress
    })
  })

  describe('constructor', function () {
    it('should set trustedForwarder', async function () {
      const { deployer } = await setup()
      const trustedForwarder = deployer['MockTrustedForwarder'].address

      expect(await deployer['KycERC20'].isTrustedForwarder(trustedForwarder)).to.be.equal(true)
    })

    it('should set collateralToken', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].underlying()).to.be.equal(deployer['InstanceMockERC20'].address)
    })

    it('should set keyringCredentials', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].keyringCredentials()).to.be.equal(
        deployer['MockKeyringCredentials'].address,
      )
    })

    it('should set policyManager', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].policyManager()).to.be.equal(deployer['MockPolicyManager'].address)
    })

    it('should set userPolicies', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].userPolicies()).to.be.equal(deployer['MockUserPolicies'].address)
    })

    it('should set policyId', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].admissionPolicyId()).to.be.equal(1)
    })

    it('should set name', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].name()).to.be.equal('KycERC20')
    })

    it('should set symbol', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycERC20'].symbol()).to.be.equal('KYC')
    })
  })

  describe('depositFor', async function () {
    it('should deposit for user', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      expect(await deployer['KycERC20'].balanceOf(user.address)).to.be.equal(amount)
    })
  })

  describe('withdrawTo', async function () {
    it('should withdraw to user', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .withdrawTo(user.address, amount)

      expect(await deployer['KycERC20'].balanceOf(user.address)).to.be.equal(0)
    })
  })

  describe('totalSupply', async function () {
    it('should return total supply', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      expect(await deployer['KycERC20'].totalSupply()).to.be.equal(amount)
    })
  })

  describe('approve', async function () {
    it('should approve', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      await deployer['KycERC20'].connect(await ethers.getSigner(user.address)).approve(user.address, amount)

      expect(await deployer['KycERC20'].allowance(user.address, user.address)).to.be.equal(amount)
    })
  })

  describe('transferFrom', async function () {
    it('should transfer from', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      await deployer['KycERC20'].connect(await ethers.getSigner(user.address)).approve(user.address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .transferFrom(user.address, deployer['KycERC20'].address, amount)

      expect(await deployer['KycERC20'].balanceOf(user.address)).to.be.equal(0)
    })
  })

  describe('transfer', async function () {
    it('should transfer', async function () {
      const { deployer, users } = await setup()

      await deployer['MockPolicyManager'].setPolicyAllowUserWhitelists(true)
      await deployer['MockPolicyManager'].setPolicyRuleId(
        keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
      )

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycERC20'].address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .depositFor(user.address, amount)

      await deployer['KycERC20'].connect(await ethers.getSigner(user.address)).approve(user.address, amount)

      await deployer['KycERC20']
        .connect(await ethers.getSigner(user.address))
        .transfer(deployer['KycERC20'].address, amount)

      expect(await deployer['KycERC20'].balanceOf(user.address)).to.be.equal(0)
    })
  })
})
