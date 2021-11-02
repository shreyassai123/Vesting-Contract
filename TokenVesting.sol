pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
  

  event TokensReleased(address token, uint256 amount);
  event TokenVestingRevoked(address token);

  address[] private _beneficiaries;

  uint256 private _cliff;
  uint256 private _start;
  uint256 private _duration;

  bool private _revocable;

  mapping (address => uint256) private _released;
  mapping (address => bool) private _revoked;

  constructor(
    address[] memory beneficiaries
  )
    public
  {
     require(beneficiaries.length == 10, "Number of beneficiaries needs to be 10");
    _beneficiaries = beneficiaries;
    _revocable = true;
    _duration = 31104000;
    _cliff = 0;
    _start = block.timestamp;
  }

  function beneficiary() public view returns(address[] memory) {
    return _beneficiaries;
  }
  
  function cliff() public view returns(uint256) {
    return _cliff;
  }
  
  function start() public view returns(uint256) {
    return _start;
  }

  function duration() public view returns(uint256) {
    return _duration;
  }

  function revocable() public view returns(bool) {
    return _revocable;
  }

  function released(address token) public view returns(uint256) {
    return _released[token];
  }


  function revoked(address token) public view returns(bool) {
    return _revoked[token];
  }


  function release(IERC20 token) public {
    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0);

    _released[address(token)] = _released[address(token)].add(unreleased);
    for (uint i=0; i<_beneficiaries.length; i++) {
            token.safeTransfer(_beneficiaries[i], unreleased);
        }
    emit TokensReleased(address(token), unreleased/_beneficiaries.length);
  }

  function revoke(IERC20 token) public onlyOwner {
    require(_revocable);
    require(!_revoked[address(token)]);

    uint256 balance = token.balanceOf(address(this));

    uint256 unreleased = _releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    _revoked[address(token)] = true;

    token.safeTransfer(owner(), refund);

    emit TokenVestingRevoked(address(token));
  }


  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token).sub(_released[address(token)]);
  }

  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(_released[address(token)]);

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
    }
  }
}