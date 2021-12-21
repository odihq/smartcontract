var OdiCoin = artifacts.require("ODITRC20Token");
const Web3 = require("web3");
const web3 = new Web3();

module.exports = function(deployer) {
  deployer.deploy(OdiCoin, web3.utils.toWei(`${100000000}`, 'ether'));
};