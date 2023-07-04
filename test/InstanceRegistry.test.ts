import { expect } from 'chai'

import { setup } from './tools/setup'
import { InstanceRegistry } from '../generated-types/ethers'
import { cast } from './helpers/caster'
import { ethers } from 'hardhat'
import { formatToContractInput } from '../utils/instances'

const format = (instances: any) => {
  return formatToContractInput(instances.deployed, 0, 0, 100)
}

describe('InstanceRegistry', async function () {
  describe('Deployment', async function () {
    it('Should deploy InstanceRegistry', async function () {
      const { deployer } = await setup()
      expect(deployer['InstanceRegistry'].address).to.be.properAddress
    })
  })

  describe('constructor', async function () {
    it('should set governance', async function () {
      const { deployer } = await setup()
      expect(await deployer['InstanceRegistry'].governance()).to.be.equal(deployer.address)
    })
  })

  describe('initInstances', async function () {
    it('should set instances', async function () {
      const { InstanceRegistry, deployer, instances, InstanceMockERC20, PGRouter } = await setup()

      await InstanceMockERC20.mint(PGRouter.address, 1000)
      await InstanceMockERC20.approve(InstanceRegistry.address, 1000)

      const formattedInstances = format(instances)
      const [formattedInstance] = formattedInstances

      await deployer['InstanceRegistry'].initInstances(formattedInstances)

      expect(cast(await InstanceRegistry.instances(formattedInstance.addr))).to.deep.equal(
        formattedInstance.instance,
      )
    })

    it('should emit event', async function () {
      const { InstanceRegistry, deployer, instances } = await setup()

      const formattedInstances = format(instances)
      const [formattedInstance] = formattedInstances

      await expect(deployer['InstanceRegistry'].initInstances(formattedInstances))
        .to.emit(InstanceRegistry, 'InstanceStateUpdated')
        .withArgs(formattedInstance.addr, formattedInstance.instance.state)
    })

    it('should revert if status is not disabled', async function () {
      const { InstanceRegistry, deployer, instances } = await setup()

      const formattedInstances = format(instances)
      const [formattedInstance] = formattedInstances

      formattedInstance.instance.state = 0

      await expect(InstanceRegistry.updateInstance(formattedInstance)).to.be.revertedWith(
        'Use removeInstance() for remove',
      )

      formattedInstance.instance.state = 1
    })

    describe('removeInstance', async function () {
      it('should emit event', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        await expect(InstanceRegistry.removeInstance(2))
          .to.emit(InstanceRegistry, 'InstanceStateUpdated')
          .withArgs(formattedInstance.addr, 0)
      })

      it('should update state', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        await InstanceRegistry.removeInstance(2)

        expect(cast(await InstanceRegistry.instances(formattedInstance.addr)).state).to.equal(0)
      })
    })

    describe('setProtocolFee', async function () {
      it('should update state', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.setProtocolFee(formattedInstance.addr, 10)

        expect(cast(await InstanceRegistry.instances(formattedInstance.addr)).protocolFeePercentage).to.equal(
          10,
        )
      })
    })

    describe('getAllInstances', async function () {
      it('should return all instances', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const contractInstances = await InstanceRegistry.getAllInstances()
        const expectedInstances = formatToContractInput(
          instances.deployed,
          0,
          0,
          ethers.BigNumber.from(100000),
        )

        expect(cast(contractInstances)).to.deep.equal(expectedInstances)
      })
    })

    describe('getAllInstanceAddresses', async function () {
      it('should return all instance addresses', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const addressesPrev = await InstanceRegistry.getAllInstanceAddresses()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        const addresses = await InstanceRegistry.getAllInstanceAddresses()

        expect(addresses).to.deep.equal(
          addressesPrev.concat(formattedInstances.map((instance) => instance.addr)),
        )
      })
    })

    describe('getPoolToken', async function () {
      it('should return pool token', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        expect(await InstanceRegistry.getPoolToken(formattedInstance.addr)).to.equal(
          formattedInstance.instance.token,
        )
      })
    })

    describe('setPGRouter', async function () {
      it('should set PGRouter', async function () {
        const { InstanceRegistry, deployer, instances, PGRouter } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        await InstanceRegistry.setPGRouter(PGRouter.address)

        expect(await InstanceRegistry.router()).to.equal(PGRouter.address)
      })

      it('should revert if not governance', async function () {
        const { InstanceRegistry, deployer, instances, PGRouter, users } = await setup()

        await expect(users[0]['InstanceRegistry'].setPGRouter(PGRouter.address)).to.be.revertedWith(
          'Not authorized',
        )
      })

      it('should emit event', async function () {
        const { InstanceRegistry, deployer, instances, PGRouter } = await setup()

        await expect(InstanceRegistry.setPGRouter(PGRouter.address))
          .to.emit(InstanceRegistry, 'RouterRegistered')
          .withArgs(PGRouter.address)
      })
    })

    describe('updateInstanceState', async function () {
      it('should update state', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        await InstanceRegistry.updateInstanceState(formattedInstance.addr, 0)

        expect(cast(await InstanceRegistry.instances(formattedInstance.addr)).state).to.equal(0)
      })

      it('should emit event', async function () {
        const { InstanceRegistry, deployer, instances } = await setup()

        const formattedInstances = format(instances)
        const [formattedInstance] = formattedInstances

        await InstanceRegistry.initInstances(formattedInstances)

        await expect(InstanceRegistry.updateInstanceState(formattedInstance.addr, 0))
          .to.emit(InstanceRegistry, 'InstanceStateUpdated')
          .withArgs(formattedInstance.addr, 0)
      })
    })
  })
})
