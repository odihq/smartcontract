const OdiCoin = artifacts.require("ODITRC20Token");
const Exchange = artifacts.require("Exchange");
const Swap = artifacts.require("Swap");
const TokenSale = artifacts.require("TokenSale");

module.exports = async function(deployer) {
  await deployer.deploy(TokenSale, Swap.address, Exchange.address, OdiCoin.address);
};