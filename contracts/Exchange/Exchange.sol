// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BaseExchange.sol";

interface ITOKEN_SALE {
    function staking(uint256 _amount, address _to) external;
}

contract Exchange is BaseExchange {
    ITOKEN_SALE public TOKEN_SALE;

    constructor(address _odi, address _tokenSale) BaseExchange(_odi) {
        TOKEN_SALE = ITOKEN_SALE(_tokenSale);
    }

    event WithdrawalToBurn(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event TransferFrom(address indexed from, address indexed to, uint256 value);

    function withdrawalToBurn(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            _balances[_from] >= _amount,
            "Exchange::withdrawal. From Balance is not sufficient."
        );

        require(
            ODI.balanceOf(address(this)) >= _amount,
            "Exchange::withdrawal. Exchange Balance is not sufficient."
        );
        ODI.transfer(_to, _amount);
        _balances[_from] -= _amount;
        emit Withdrawal(_to, _amount);
    }

    function transferFrom(
        address _from,
        uint256 _amount,
    ) external onlyOwner {
        require(_from != address(0), "Exchange: transfer from the zero address");

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "Exchange::transferFrom Balance is not sufficient.");
        require(
            ODI.balanceOf(address(this)) >= _amount,
            "Exchange::transferFrom. Exchange Balance is not sufficient."
        );
        ODI.transfer(address(TOKEN_SALE), _amount);
        _balances[_from] -= _amount;

        emit TransferFrom(_from, address(TOKEN_SALE), _amount);
    }
}
