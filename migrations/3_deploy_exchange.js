const OdiCoin = artifacts.require("ODITRC20Token");
const Exchange = artifacts.require("Exchange");

module.exports = async function(deployer) {
  await deployer.deploy(Exchange, OdiCoin.address);
};