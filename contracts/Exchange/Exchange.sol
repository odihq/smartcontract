// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BaseExchange.sol";

contract Exchange is BaseExchange {
    constructor(address _odi) BaseExchange(_odi) {}

    event WithdrawalToBurn(
        address indexed from,
        address indexed to,
        uint256 value
    );

    function withdrawalToBurn(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            _balances[_from] >= _amount,
            "Swap::withdrawal. From Balance is not sufficient."
        );

        require(
            ODI.balanceOf(address(this)) >= _amount,
            "Swap::withdrawal. Exchange Balance is not sufficient."
        );
        ODI.transfer(_to, _amount);
        _balances[_from] -= _amount;
        emit Withdrawal(_to, _amount);
    }
}
