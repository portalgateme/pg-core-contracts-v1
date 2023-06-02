import { expect } from 'chai'

import { setup } from './tools/setup'
import { ethers, network } from 'hardhat'
import { keccak256 } from 'ethers/lib/utils'
import { BigNumber } from 'ethers'

const setBalance = async (user: string, amount: BigNumber) => {
  await network.provider.send('hardhat_setBalance', [user, '0x' + amount.toString()])
}

describe('KycETH', function () {
  describe('Deployment', function () {
    it('Should deploy KycETH', async function () {
      const { deployer } = await setup()
      expect(deployer['KycETH'].address).to.be.properAddress
    })
  })

  describe('constructor', function () {
    it('should set trustedForwarder', async function () {
      const { deployer } = await setup()
      const trustedForwarder = deployer['MockTrustedForwarder'].address

      expect(await deployer['KycETH'].isTrustedForwarder(trustedForwarder)).to.be.equal(true)
    })

    it('should set keyringCredentials', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycETH'].keyringCredentials()).to.be.equal(
        deployer['MockKeyringCredentials'].address,
      )
    })

    it('should set policyManager', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycETH'].policyManager()).to.be.equal(deployer['MockPolicyManager'].address)
    })

    it('should set userPolicies', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycETH'].userPolicies()).to.be.equal(deployer['MockUserPolicies'].address)
    })

    it('should set policyId', async function () {
      const { deployer } = await setup()

      expect(await deployer['KycETH'].admissionPolicyId()).to.be.equal(1)
    })
  })

  describe('depositFor', async function () {
    it('should deposit for user', async function () {
      const { deployer, users } = await setup()

      const user = users[0]

      await setBalance(users[0].address, ethers.utils.parseEther('1'))

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      expect(await deployer['KycETH'].balanceOf(user.address)).to.be.equal(amount)
    })
  })

  describe('withdrawTo', async function () {
    it('should withdraw to user', async function () {
      const { deployer, users } = await setup()

      const user = users[0]

      await setBalance(users[0].address, ethers.utils.parseEther('1'))

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).withdrawTo(user.address, amount)

      expect(await deployer['KycETH'].balanceOf(user.address)).to.be.equal(0)
    })
  })

  describe('totalSupply', async function () {
    it('should return total supply', async function () {
      const { deployer, users } = await setup()

      const user = users[0]

      await setBalance(users[0].address, ethers.utils.parseEther('1'))

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      expect(await deployer['KycETH'].totalSupply()).to.be.equal(amount)
    })
  })

  describe('approve', async function () {
    it('should approve', async function () {
      const { deployer, users } = await setup()

      const user = users[0]

      const amount = ethers.utils.parseEther('1')
      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).approve(user.address, amount)

      expect(await deployer['KycETH'].allowance(user.address, user.address)).to.be.equal(amount)
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
      await setBalance(users[0].address, amount)

      await deployer['InstanceMockERC20'].mint(user.address, amount)

      await deployer['InstanceMockERC20']
        .connect(await ethers.getSigner(user.address))
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).approve(user.address, amount)

      await deployer['KycETH']
        .connect(await ethers.getSigner(user.address))
        .transferFrom(user.address, deployer.address, amount)

      expect(await deployer['KycETH'].balanceOf(deployer.address)).to.be.equal(amount)
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
        .approve(deployer['KycETH'].address, amount)

      await deployer['KycETH'].connect(await ethers.getSigner(user.address)).depositFor({
        value: amount,
      })

      await deployer['KycETH']
        .connect(await ethers.getSigner(user.address))
        .transfer(deployer.address, amount)

      expect(await deployer['KycETH'].balanceOf(deployer.address)).to.be.equal(amount)
    })
  })
})
