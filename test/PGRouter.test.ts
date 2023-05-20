import { expect } from "chai";

import { setup } from "./tools/setup";

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
  });

  describe.skip("withdraw", async function () {});
});
