// SPDX-License-Identifier: MIT
pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "../utils/address.sol";

contract ODITRC20Token is ERC20, Ownable {
    using Address for address;

    string public name = "ODI";
    string public symbol = "ODI";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 100000000000000000000000000;

    constructor() public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function multisend(address[] calldata to, uint256[] calldata values)
        external
        onlyOwner
        returns (uint256)
    {
        require(to.length == values.length);
        require(to.length < 100);
        for (uint256 i; i < to.length; i++) {
            transfer(to[i], values[i]);
        }
        return (to.length);
    }

    function burnTokens(uint256 amount)
        external
        onlyOwner
        returns (bool success)
    {
        _burn(msg.sender, amount);
        return true;
    }
}
