const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CrowdfundingModule", (m) => {
  const crowdFunding = m.contract("Crowdfunding");

  return { crowdFunding };
});
