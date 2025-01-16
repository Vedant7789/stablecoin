//SPDX-License-Identifier:MIT


pragma solidity ^0.8.28;
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard{

    error DSCEngine_NeedsMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeSame();
    error DSCEngine_NotAllowedToken();
    error DSCEngine_TransferFailed();
    error DSCEngine_BreaksHealthFactor(uint256 healthFactor);
    error  DSCEngine_MintFailes();


    uint256 private constant ADDITIONAL_FEED_PRECISION=1e10;
    uint256 private constant PRECISION=1e18;
    uint256 private constant LIQUIDATION_THRESHOLD=50;
    uint256 private constant LIQUIDATION_PRECISION=100;
    uint256 private constant MIN_HEALTH_FACTOR=1;

    mapping(address token=> address priceFeed) private s_priceFeeds; 
    mapping(address user=>mapping(address token=>uint256 amount))
    private s_collateralDeposited;
    mapping(address user=>uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private  immutable s_dsc; 

     event CollateralDeposited(address indexed user,address indexed token,uint256 amount);
     event CollateralRedeemed(address indexed user,address indexed token,uint256 indexed amount);


    modifier moreThanZero(uint256 amount){
        if(amount==0){
           
         revert DSCEngine_NeedsMoreThanZero();
        }
        _;
    }
    modifier isAllowedToken(address Token){
        if(s_priceFeeds[token]==address(0)){
            revert DSCEngine_NotAllowedToken();
        }
        _;
    }


    
    constructor(address[] memory tokenAddresses,
    address[] memory priceFeedAddresses,
    address dscAddress ){
        if(tokenAddresses.length!=priceFeedAddresses.length){
            revert      DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeSame();

        }
        for (uint256 i=0;i<tokenAddresses.length;i++){
            s_priceFeeds[tokenAddresses[i]]=priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);


        }
        i_dsc=DecentralizedStableCoin(dscAddress);

    }



    function depositCollateralAndMintDSC(address tokenCollateralAddress,uint256 amountCollateral,uint256 amountDscToMint) external{
         depositCollateral(tokenCollateralAddress, amountCollateral);
         mintDSC(amountDscToMint);

    }

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )  public moreThanZero(amountCollateral)
    isAllowedToken(tokenCollateralAddress)
    nonReentrant{
        s_collateralDeposited[msg.sender][tokenCollaternalAddress]+=amountCollateral;
        emit CollateralDeposited(msg.sender,tokenCollateralAddress,amountCollateral);
        bool success=IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if(!success){
            revert DSCEngine_Transferfailed();
        }
    }   

    function redeemCollateralForDSC(address tokenCollateralAddress,uint256 amountCollateral,uint256 amountDscToBurn) external{
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);

    }
     
    function redeemCollateral(address tokenCollateralAddress,uint256 amountCollateral) external
    moreThanZero(amountCollateral)
    nonReentrant{
        s_collateralDeposited[msg.sender][tokenCollateralAddress]-=amountCollateral;
        emit CollateralRedeemed(msg.sender,tokenCollateralAddress,amountCollateral);
        bool success=IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if(!success){
            revert DSCEngine_Transferfailed();

        }
        _revertIfHealthFactorIsBroken(msg.sender);



    }

     function mintDSC(uint256 amountDscToMint) public moreThanZero(amountDscToMint)  nonReentrant{
        s_DSCMinted[msg.sender]+=amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted=i_dsc.mint(msg.sender,amountDscToMint);
        if(!minted){
            revert DSCEngine_MintFailes();
        }
     }

     function burnDSC(uint256 amount) public moreThanZero(amount){
        s_DSCMinted[msg.sender]-=amount;
        bool success=i_dsc.transferFrom(msg.sender.address(this),amount);
        if(!success){
            revert DSCEngine_Transferfailed();

        }
        i_dsv.burn(amount)
     }

     function liquidate() external{}

     function getHealthFactor() external{}

     function _getAccountInformation(address user)private view returns(uint256 totalDscMinted,uint256 collateralValueInUsd ){
        totalDscMinted=s_DSCMinted[user];
        collateralValueInUsd=getAccountCollateralValue(user);

     }

     function _healthFactor(address user) private view returns(uint256){
        (uint256 totalDscMinted,uint256 collateralValueInUsd)=_getAccountInformation(user);
        uint256 collateralAdjustedForTheThreshold=(collateralValueInUsd*LIQUIDATION_THRESHOLD)/LIQUIDATION_PRECISION;
         return (collateralAdjustedForTheThreshold*PRECISION)/totalDscMinted;

     }
     function _revertIfHealthFactorIsBroken(address user) internal view{
        uint256 userHealthFactor=_healthFactor(user);
        if(userHealthFactor<MIN_HEALTH_FACTOR){
            
        }

     }







     function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd){
        for(uint256 i=0;i<s_collateralTokens.length;i++){
            address token=s_collateralTokens.length[i];
            uint256 amount=s_collateralDeposited[user][token];
            totalCollateralValueInUsd+=getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;

     }
     function getUsdValue(adddress token,uint256 amount) public view returns (uint256){
        AggregatorV3Interface priceFeed=AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price ,,,)=priceFeed.latestRoundData();

        return ((uint256(price)*ADDITIONAL_FEED_PRECISION)*amount)/ PRECISION;


     }


}