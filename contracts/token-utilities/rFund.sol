pragma solidity ^0.5.0;
import "../Roobee.sol";
import "./Ownable.sol";

contract RoobeeFund is Ownable {

    using SafeMath for uint256;

    struct Category {
        uint amount;
        uint limit;
    }

    mapping (uint => Category) public categories ;


    RoobeeToken constant public ROOBEE = RoobeeToken(0x352e2610eDb09F7Cc3a440a0CeB444dAbfAAc38b);

    function getBalance () public view returns(uint256)  {
        return ROOBEE.balanceOf(address(this));
    }

    function payReward (uint _category, address _to) public onlyOwner returns(bool) {
        return ROOBEE.transfer(_to, categories[_category].amount);
    }

    function addCategory(uint _ID, uint _amount, uint _limit) public onlyOwner  {
        Category memory categoryData;
        categoryData.amount = _amount;
        categoryData.limit = _limit;
        categories[_ID] = categoryData;
    }

}
