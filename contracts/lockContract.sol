pragma solidity ^0.5.0;
import "./IERC20.sol";

contract lockContract {

    struct LockedParams {
        uint256 forTimestamp;
        uint256 value;
        uint256 fromTimestamp;
    }

    mapping (address => LockedParams) private _locked;
    mapping (uint256 => string) private _statuses;
    address private owner;
    address private roobeeTokenAddress;

    constructor (address _token) public {
        owner = msg.sender;
        roobeeTokenAddress = _token;
    }

    function approvalFallback(address _from, uint256 _value, address _token, string memory _extraData) public {
        require(_token == roobeeTokenAddress);
        require(IERC20(_token).transferFrom(_from, address(this), _value));
        LockedParams memory lockedData;
        lockedData.value = _value;
        lockedData.forTimestamp = stringToUint(_extraData);
        lockedData.fromTimestamp = now;
    }


    function stringToUint(string memory s) internal view returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }


    function getTokens(address _to) public {
        require(_to == msg.sender || msg.sender == owner);
        IERC20(roobeeTokenAddress).transfer(_to, _locked[_to].value);
    }


    function renewLock(uint256 _timestamp) public {
        _locked[msg.sender].forTimestamp = _timestamp;
        _locked[msg.sender].fromTimestamp = now;
    }


    function getLockedPeriod(address holder) pure public returns(uint) {
        return (_locked[holder].forTimestamp -  _locked[holder].fromTimestamp);
    }

    function getStatus(address holder)  view public returns(string memory) {
        return (_statuses[getLockedPeriod(holder)]);
    }

}
