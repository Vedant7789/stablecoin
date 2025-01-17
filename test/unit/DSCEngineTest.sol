
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";


contract DSCEngineTest is Test{
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;


    function setUp() public{
        deployer=new DeployDSC();
        (dsc,dsce,config)=deployer.run();
        (ethUsdPriceFeed,,weth,,)=config.activeNetworkConfig();


    }

    function testGetUsdValue() public{
        uint256 ethAmount=15e18;
        uint256 expectedUsd=3000e18;

        uint256 actualUsd=dsce.getUsdValue(weth,ethAmount);
        assertEq(expectedUsd,actualUsd);
        

    }


}
