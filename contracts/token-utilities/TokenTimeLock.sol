pragma solidity ^0.5.0;

import "../SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 *
 * For a more complete vesting schedule, see {TokenVesting}.
 */
contract TokenTimelock is Ownable {
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    struct FreezeParams {
        uint256 releaseTime;
        uint256 initValue;
        uint256 monthlyUnlock;
        uint256 currentBalance;
    }

    mapping (address => FreezeParams) public frozenTokens;
    uint256 public totalReserved;


    constructor (IERC20 token) public {
        _token = token;
    }
    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    function totalHeld() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    event tokensHeld(address _beneficiary, uint256 _value);

    function holdTokens(
        address _beneficiary,
        uint256 _value,
        uint256 _releaseTime,
        uint256 _monthlyUnlock) onlyOwner public
    {
        require(totalHeld().sub(totalReserved) >= _value, "not enough tokens");
        frozenTokens[_beneficiary] = FreezeParams(_releaseTime,
            _value,
            _monthlyUnlock,
            _value);
        totalReserved = totalReserved.add(_value);
        emit tokensHeld(_beneficiary, _value);
    }

    function freezeOf(address _beneficiary) public view returns (uint256) {
        if (frozenTokens[_beneficiary].releaseTime <= now){
            if (frozenTokens[_beneficiary].monthlyUnlock != 0){
                uint256  monthsPassed;
                monthsPassed = now.sub(frozenTokens[_beneficiary].releaseTime).div(30 days);
                uint256 unlockedValue = monthsPassed.div(100).mul(frozenTokens[_beneficiary].monthlyUnlock);
                return frozenTokens[_beneficiary].initValue.sub(unlockedValue);
            }
            else {
                return 0;
            }
        }
        else
        {
            return frozenTokens[_beneficiary].initValue;
        }
    }

    /**
     * @return the beneficiaries available balance of the tokens.
     */
    function availableBalance(address _beneficiary) public view returns (uint256) {
        return frozenTokens[_beneficiary].currentBalance.sub(freezeOf(_beneficiary));
    }


    function release(address _beneficiary) public {
        uint256 value = availableBalance(_beneficiary);
        require(value > 0, "TokenTimelock: no tokens to release");
        require(_token.balanceOf(address(this)) >= value, "insuficient funds");
        _token.transfer(_beneficiary, value);
        totalReserved = totalReserved.sub(value);
    }

    function unfreeze(address _to, uint256 _value) public onlyOwner {
        require(totalHeld().sub(totalReserved) >= _value);
        _token.transfer(_to, _value);
    }
}
