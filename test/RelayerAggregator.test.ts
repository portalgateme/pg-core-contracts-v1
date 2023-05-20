import { expect } from "chai";

import { setup } from "./tools/setup";

describe("RelayerAggregator", async function () {
  describe("Deployment", async function () {
    it("Should deploy RelayerAggregator", async function () {
      const { deployer } = await setup();
      expect(deployer["RelayerAggregator"].address).to.be.properAddress;
    });
  });

  describe("constructor", async function () {
    it("should set relayerRegistry", async function () {
      const { deployer } = await setup();
      expect(await deployer["RelayerAggregator"].relayerRegistry()).to.be.equal(
        deployer["RelayerRegistry"].address
      );
    });
  });

  describe("relayersData", async function () {
    it("should return relayers data", async function () {
      const { deployer, users } = await setup();
      const relayer = users[0];
      await deployer["RelayerRegistry"].add(relayer.address);
      const relayersData = await deployer["RelayerAggregator"].relayersData([
        relayer.address,
      ]);
      expect(relayersData[0].balance).to.be.equal(0);
      expect(relayersData[0].isRegistered).to.be.true;
    });
  });
});
