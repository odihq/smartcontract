// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BaseSwapExchange.sol";

interface IEXCHANGE {
    function transferFromTokenSale(address recipient, uint256 amount) external;
}

contract Swap is BaseSwapExchange {
    event TransferFrom(address indexed from, address indexed to, uint256 value);

    IEXCHANGE public EXCHANGE;

    constructor(address _odi, address _exchange) BaseSwapExchange(_odi) {
        EXCHANGE = IEXCHANGE(_exchange);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _coefficient
    ) external onlyOwner {
        bool distibutionToExchange = true;
        require(_from != address(0), "Swap: transfer from the zero address");
        require(_to != address(0), "Swap: transfer to the zero address");

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "Swap:: Balance is not sufficient.");
        _balances[_from] -= _amount;
        if ((_coefficient / 10**18) == 1) {
            distibutionToExchange = false;
        }
        uint256 swapAmount = _amount;
        if (distibutionToExchange == true) {
            swapAmount = (_amount * _coefficient) / 10**18;
            uint256 exchangeAmount = _amount - swapAmount;
            require(
                ODI.balanceOf(address(this)) >= exchangeAmount,
                "Swap::transferFrom. Swap Balance is not sufficient."
            );
            ODI.transfer(address(EXCHANGE), exchangeAmount);
            EXCHANGE.transferFromTokenSale(_to, exchangeAmount);
        }
        _balances[_to] += swapAmount;

        emit TransferFrom(_from, _to, _amount);
    }

    function setExchangeContract(address _exchange) external onlyOwner {
        EXCHANGE = IEXCHANGE(_exchange);
    }
}
