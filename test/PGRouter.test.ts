import { expect } from "chai";

import { setup } from "./tools/setup";
import { ethers } from "hardhat";

describe("PGRouter", async function () {
  describe("Deployment", async function () {
    it("Should deploy PGRouter", async function () {
      const { deployer } = await setup();
      expect(deployer["PGRouter"].address).to.be.properAddress;
    });
  });

  describe("constructor", async function () {
    it("should set relayerRegistry", async function () {
      const { deployer } = await setup();
      expect(await deployer["PGRouter"].relayerRegistry()).to.be.equal(
        deployer["RelayerRegistry"].address
      );
    });
    it("should set instanceRegistry", async function () {
      const { deployer } = await setup();
      expect(await deployer["PGRouter"].instanceRegistry()).to.be.equal(
        deployer["InstanceRegistry"].address
      );
    });
    it("should set gevernance", async function () {
      const { deployer } = await setup();
      expect(await deployer["PGRouter"].governance()).to.be.equal(
        deployer.address
      );
    });
  });

  describe("backupNotes", async function () {
    it("should emit event", async function () {
      const { PGRouter, deployer } = await setup();

      const notes = [ethers.utils.formatBytes32String("test")];

      await expect(deployer["PGRouter"].backupNotes(notes))
        .to.emit(PGRouter, "EncryptedNote")
        .withArgs(deployer.address, notes[0]);
    });
  });

  describe("rescueTokens", async function () {
    it("should rescue tokens", async function () {
      const { PGRouter, deployer, InstanceMockERC20 } = await setup();

      await InstanceMockERC20.mint(PGRouter.address, 1000);

      await PGRouter.rescueTokens(
        InstanceMockERC20.address,
        deployer.address,
        1000
      );

      expect(await InstanceMockERC20.balanceOf(deployer.address)).to.equal(
        1000
      );
    });
  });

  describe.skip("withdraw", async function () {});
});
