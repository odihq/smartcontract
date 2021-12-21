// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../utils/address.sol";

interface ISWAP {
    function transferFromTokenSale(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IEXCHANGE {
    function transferFromTokenSale(address recipient, uint256 amount)
        external
        returns (bool);
}

contract TokenSale is Ownable {
    using Address for address;

    event EDistribution(
        address indexed contractAddress,
        address indexed toWallet,
        uint256 amount
    );

    IERC20 public ODI;
    ISWAP public SWAP;
    IEXCHANGE public EXCHANGE;

    constructor(
        address _swap,
        address _exchange,
        address _odi
    ) {
        SWAP = ISWAP(_swap);
        EXCHANGE = IEXCHANGE(_exchange);
        ODI = IERC20(_odi);
    }

    function _calcul(
        uint256 a,
        uint256 b,
        uint256 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    function distribution(
        uint256 _amount,
        uint256 _coefficient,
        address _to
    ) external onlyOwner {
        bool distibutionToExchange = true;
        uint256 swapAmount = _calcul(_amount, _coefficient, 18);
        uint256 exchangeAmount = _amount - swapAmount;
        if ((_coefficient / 10**18) == 1) {
            distibutionToExchange = false;
        }

        uint256 tokenSaleBalance = ODI.balanceOf(address(this));
        require(
            tokenSaleBalance >= _amount,
            "TokenSale::distribution: Amount more than token sale ODI balance"
        );

        ODI.transfer(_to, swapAmount);
        SWAP.transferFromTokenSale(_to, swapAmount);
        emit EDistribution(address(SWAP), _to, swapAmount);
        if (distibutionToExchange) {
            ODI.transfer(_to, exchangeAmount);
            EXCHANGE.transferFromTokenSale(_to, exchangeAmount);
            emit EDistribution(address(EXCHANGE), _to, exchangeAmount);
        }
    }
}
