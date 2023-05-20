import { expect } from "chai";

import { setup } from "./tools/setup";

describe("RelayerRegistry", async function () {
  describe("Deployment", async function () {
    it("Should deploy RelayerRegistry", async function () {
      const { deployer } = await setup();
      expect(deployer["RelayerRegistry"].address).to.be.properAddress;
    });
  });

  describe("constructor", async function () {
    it("should set owner", async function () {
      const { deployer } = await setup();
      expect(await deployer["RelayerRegistry"].owner()).to.be.equal(
        deployer.address
      );
    });
  });

  describe("add", async function () {
    it("should add a relayer", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      expect(await deployer["RelayerRegistry"].isRelayer(relayer.address)).to.be
        .true;
    });

    it("should emit RelayerAdded event", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await expect(deployer["RelayerRegistry"].add(relayer.address))
        .to.emit(deployer["RelayerRegistry"], "RelayerAdded")
        .withArgs(relayer.address);
    });

    it("should revert if relayer is already add", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      await expect(
        deployer["RelayerRegistry"].add(relayer.address)
      ).to.be.revertedWith("The relayer already exists");
    });

    it("should revert if caller is not owner", async function () {
      const { users } = await setup();
      const relayer = users[0];
      await expect(
        relayer["RelayerRegistry"].add(relayer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("remove", async function () {
    it("should remove a relayer", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      await deployer["RelayerRegistry"].remove(relayer.address);
      expect(await deployer["RelayerRegistry"].isRelayer(relayer.address)).to.be
        .false;
    });

    it("should emit RelayerRemoved event", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      await expect(deployer["RelayerRegistry"].remove(relayer.address))
        .to.emit(deployer["RelayerRegistry"], "RelayerRemoved")
        .withArgs(relayer.address);
    });

    it("should revert if relayer does not exist", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await expect(
        deployer["RelayerRegistry"].remove(relayer.address)
      ).to.be.revertedWith("The relayer does not exist");
    });

    it("should revert if caller is not owner", async function () {
      const { users } = await setup();
      const relayer = users[0];
      await expect(
        relayer["RelayerRegistry"].remove(relayer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("isRelayerRegistered", async function () {
    it("should return true if relayer is registered", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      expect(
        await deployer["RelayerRegistry"].isRelayerRegistered(relayer.address)
      ).to.be.true;
    });

    it("should return false if relayer is not registered", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      expect(
        await deployer["RelayerRegistry"].isRelayerRegistered(relayer.address)
      ).to.be.false;
    });
  });
});
