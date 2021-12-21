var OdiCoin = artifacts.require("ODITRC20Token");

module.exports = function(deployer) {
  deployer.deploy(OdiCoin);
};