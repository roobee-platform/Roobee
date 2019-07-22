var Roobee = artifacts.require("RoobeeToken");
var rFund = artifacts.require("RewardFund");
module.exports = function(deployer) {
  deployer.deploy(Roobee).then(function() {
    return deployer.deploy(rFund, Roobee.address);
  });
};
