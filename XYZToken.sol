pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XYZToken is ERC20 {
    constructor() public ERC20("XYZ Token", "XYZ") {
        uint256 initialSupply = 100000000;
        _mint(msg.sender, initialSupply);
    }
    
}