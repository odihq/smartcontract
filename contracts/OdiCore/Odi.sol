// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../utils/address.sol";

contract ODITRC20Token is ERC20, Ownable {
    using Address for address;

    constructor(uint256 initialSupply) ERC20("ODI", "ODI") {
        _mint(msg.sender, initialSupply);
    }

    function multisend(address[] memory to, uint256[] memory values)
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
