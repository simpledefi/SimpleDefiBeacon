var beaconApp = artifacts.require("combine_beacon");
const OWNER_ADDR = "0x0e0435b1ab9b9dcddff2119623e25be63ef5cb6e";

module.exports = async function(deployer, network, accounts) {
  if (config.network == "development") {
    accounts = await web3.eth.getAccounts();
    console.log("accounts: ", accounts);
  }

  await deployer.deploy(beaconApp,{from: OWNER_ADDR});
  var beacon = await beaconApp.deployed();
  console.log("Beacon: ", beacon.address);
  };

