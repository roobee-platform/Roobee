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
        uint256 monthlyUnlockPercent;
        uint256 currentBalance;
    }

    mapping (address => FreezeParams) public frozenTokens;
    mapping (address => bool) private _admins;
    uint256 public totalReserved;

    modifier onlyAdmin() {
        require(isAdmin(), " caller is not the admin");
        _;
    }

    function isAdmin() public view returns (bool) {
        return _admins[msg.sender];
    }

    function addAdmin(address admin) public onlyOwner {
        _admins[admin] = true;
    }

    function renounceAdmin(address admin) public onlyOwner {
        _admins[admin] = false;
    }

    constructor (IERC20 token) public {
        _token = token;
        _admins[msg.sender] = true;
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
        uint256 _monthlyUnlockPercent) onlyAdmin public
    {
        require(_releaseTime.sub(now) <= 365 days, "freeze period is too long");
        require(frozenTokens[_beneficiary].currentBalance == 0, "there are unspended tokens");
        require(totalHeld().sub(totalReserved) >= _value, "not enough tokens");
        frozenTokens[_beneficiary] = FreezeParams(_releaseTime,
            _value,
            _monthlyUnlockPercent,
            _value);
        totalReserved = totalReserved.add(_value);
        emit tokensHeld(_beneficiary, _value);
    }

    function freezeOf(address _beneficiary) public view returns (uint256) {
        if (frozenTokens[_beneficiary].releaseTime <= now){
            if (frozenTokens[_beneficiary].monthlyUnlockPercent != 0){
                uint256  monthsPassed;
                monthsPassed = now.sub(frozenTokens[_beneficiary].releaseTime).div(30 days);
                uint256 unlockedValue = frozenTokens[_beneficiary].initValue.mul(monthsPassed).mul(frozenTokens[_beneficiary].monthlyUnlockPercent).div(100);
                if (frozenTokens[_beneficiary].initValue < unlockedValue){
                    return 0;
                }
                else {
                    return frozenTokens[_beneficiary].initValue.sub(unlockedValue);
                }
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
        totalReserved = totalReserved.sub(value);
        frozenTokens[_beneficiary].currentBalance = frozenTokens[_beneficiary].currentBalance.sub(value);
        _token.transfer(_beneficiary, value);
    }

    function unfreeze(address _to, uint256 _value) public onlyAdmin {
        require(totalHeld().sub(totalReserved) >= _value);
        _token.transfer(_to, _value);
    }
}
