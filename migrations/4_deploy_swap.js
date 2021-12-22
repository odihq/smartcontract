const OdiCoin = artifacts.require("ODITRC20Token");
const Exchange = artifacts.require("Exchange");
const Swap = artifacts.require("Swap");

module.exports = async function(deployer) {
  await deployer.deploy(Swap, OdiCoin.address, Exchange.address);
};