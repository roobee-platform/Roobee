var Roobee = artifacts.require("RoobeeToken");
module.exports = function(deployer) {
  // deploy HumansToken
  deployer.deploy(Roobee)
};
