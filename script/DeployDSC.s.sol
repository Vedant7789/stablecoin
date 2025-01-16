//SPDX-License-Identifier:MIT


pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import{DecentralizedStableCoin} from '../src/DecentralizedStableCoin.sol';
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract DeployDSC is Script{
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;


    funtion run() external returns (DSCEngine,DecentralizedStableCoin);
    HelperConfig config=new HelperConfig();
    (address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
)=config.activeNetworkConfig();
tokenAddresses=[weth,wbtc];
priceFeedAddresses=[wethUsdPriceFeed,wbtcUsdPriceFeed];


    vm.startBroadcast(deployerKey);
    DecentralizedCoin dsc=new DecentralizedStableCoin();
    DSCEngine engine=new DSCEngine(tokenAddresses,priceFeedAddresses,address(dsc));
    dsc.transferOwnership(address(engine));
    vm.stopBroadcast();
    return (dsc,engine);

}