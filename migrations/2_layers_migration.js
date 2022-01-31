var MyContract = artifacts.require("Layers");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(MyContract);
};