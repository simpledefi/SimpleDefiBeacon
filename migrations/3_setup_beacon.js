var beaconApp = artifacts.require("combine_beacon");
const OWNER_ADDR = "0x0e0435b1ab9b9dcddff2119623e25be63ef5cb6e";
const HARVESTER = "0x42a515c1EDB651F4c69c56E05578D2805D6451eB";
const BEACON_ADDR="";

function amt(val) {
    return  parseFloat(val).toFixed(18).replace(".","").toString();
}
  
  
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = async function(deployer, network, accounts) {
    let beacon;
    if (BEACON_ADDR)
        beacon = await beaconApp.at(BEACON_ADDR);
    else
        beacon = await beaconApp.deployed();

    console.log("beacon:", beacon.address);

    console.log("Setting Pancakeswap");
    await beacon.setExchangeInfo('PANCAKESWAP',
        '0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652', //chefContract
        '0x10ED43C718714eb63d5aA57B78B54704E256024E', //routerContract
        true,                                        // Is Pancakeswap V2?
        '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', //rewardToken
        'pendingCake(uint256,address)',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        'MULTIEXCHANGE',
        'MULTIEXCHANGEPOOLED',{from: OWNER_ADDR}
    );
   
    console.log("Setting Babyswap");
    await beacon.setExchangeInfo('BABYSWAP', // really BABYSWAP
        '0xdfaa0e08e357db0153927c7eabb492d1f60ac730', //chefContract
        '0x325E343f1dE602396E256B67eFd1F61C3A6B38Bd', //routerContract
        false,                                        // Is Pancakeswap V2?
        '0x53E562b9B7E5E94b81f10e96Ee70Ad06df3D2657', //rewardToken
        'pendingCake(uint256,address)', //pendingCall
        '0x55d398326f99059ff775485246999027b3197955', //intermediateToken
        '0x0000000000000000000000000000000000000000',
        'MULTIEXCHANGE',
        'MULTIEXCHANGEPOOLED',{from: OWNER_ADDR}
    );
  
    console.log("Setting Apeswap");
    await beacon.setExchangeInfo('APESWAP', // really BABYSWAP
        '0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9', //chefContract
        '0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7', //routerContract
        false,                                        // Is Pancakeswap V2?
        '0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95', //rewardToken
        'pendingCake(uint256,address)', //pendingCall
        '0x0000000000000000000000000000000000000000', //intermediateToken
        '0x0000000000000000000000000000000000000000',
        'MULTIEXCHANGE',
        'MULTIEXCHANGEPOOLED',{from: OWNER_ADDR}
    );
  
    console.log("Setting BiSwap");
    await beacon.setExchangeInfo('BISWAP', 
        '0xDbc1A13490deeF9c3C12b44FE77b503c1B061739', //chefContract
        '0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8', //routerContract
        false,                                        // Is Pancakeswap V2?
        '0x965F527D9159dCe6288a2219DB51fc6Eef120dD1', //rewardToken
        'pendingBSW(uint256, address)', //pendingCall
        '0x0000000000000000000000000000000000000000', //intermediateToken
        '0x0000000000000000000000000000000000000000',
        'MULTIEXCHANGE',
        'MULTIEXCHANGEPOOLED',{from: OWNER_ADDR}
    );
    
    await beacon.setFee('DEFAULT','HARVESTSOLOGAS',7339,0,{from: OWNER_ADDR});
    await beacon.setFee('DEFAULT','HARVESTPOOLGAS',7339,0,{from: OWNER_ADDR});
  
    if (config.network == "development") {
        console.log("Setting HARVEST/COLLECTOR");
        await beacon.setAddress("HARVESTER",accounts[0],{from: OWNER_ADDR});
        await beacon.setAddress("ADMINUSER",accounts[0],{from: OWNER_ADDR});
        await beacon.setAddress("FEECOLLECTOR",accounts[2],{from: OWNER_ADDR});        
    }
    else {        
        console.log("Setting HARVEST/COLLECTOR");
        await beacon.setAddress("HARVESTER",HARVESTER,{from: OWNER_ADDR});
 
        console.log("Setting ADMINUSER");
        await beacon.setAddress("ADMINUSER",HARVESTER,{from: OWNER_ADDR});
  
        console.log("Setting FEECOLLECTOR");
        await beacon.setAddress("FEECOLLECTOR",HARVESTER,{from: OWNER_ADDR});

        console.log("Setting GODUSER");
        await beacon.setAddress("GODUSER",OWNER_ADDR,{from: OWNER_ADDR});

    }
    console.log("HARVESTER:", await beacon.getAddress("HARVESTER"));
    console.log("ADMINUSER:", await beacon.getAddress("ADMINUSER"));
    console.log("FEECOLLECTOR:", await beacon.getAddress("FEECOLLECTOR"));
    console.log("GODUSER:", await beacon.getAddress("GODUSER"));

    console.log("Liquidation Fee");
    await beacon.setFee("DEFAULT","LIQUIDATIONFEE",amt(0.5),0,{from: OWNER_ADDR});

    console.log("minDeposit");
    await beacon.setFee("DEFAULT","MINDEPOSITTIME",72 * (60*60),0,{from: OWNER_ADDR});

    console.log("liquidationGas");
    await beacon.setFee("DEFAULT","LIQUIDATIONGAS",10000,0,{from: OWNER_ADDR});

    console.log("Harvest")
    await beacon.setFee('DEFAULT', 'HARVEST', amt(4.5), 0,{from: OWNER_ADDR});    

    console.log("DEPOSIT FEE");
    await beacon.setFee('DEFAULT', 'DEPOSITFEE', amt(.1), 0,{from: OWNER_ADDR});    
    console.log("DONE");
}
