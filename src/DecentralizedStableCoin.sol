//SPDX-License-Identifier:MIT


pragma solidity ^0.8.28;
import {ERCBurnable,ERC20} from "@openzeppelin/contracts/ERC20/extensions/ERCBurnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStableCoin is ERC20Burnable,Ownable{
    error DecentralizedStableCoin_MustBeMoreThan0();
    error DecentralizedStableCoin_BurnAmountExceedsBalance();
    error DecentralizedStableCoin_NotZeoAdrress();




    constructor() ERC20("DecentralizedStableCoin","DSC"){}
    function burn(uint256 _amount) public override onlyOwner{
        uint256 balance=balanceOf(msg.sender);
        if(_amount<=0){
            revert DecentralizedStableCoin_MustBeMoreThan0();
        }
        if(blance<_amount){
            revert DecentralizedStableCoin_BurnAmountExceedsBalance();

        }
        super.burn(_amount);
    }
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool){
        if(_to==address(0)){
            revert DecentralizedStableCoin_NotZeroAddress();

        }
        if(_amount<=0){
            revert DecentralizedStableCoin_MustBeMoreThan0();

        }
        _mint(_to,_amount);
        return true;
    }

}