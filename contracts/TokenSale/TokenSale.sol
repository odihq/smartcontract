// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../utils/address.sol";

interface ISWAP {
    function transferFromTokenSale(address recipient, uint256 amount) external;
}

interface IEXCHANGE {
    function transferFromTokenSale(address recipient, uint256 amount) external;
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

    function distribution(
        uint256 _amount,
        uint256 _coefficient,
        address _to
    ) external onlyOwner {
        bool distibutionToExchange = true;
        uint256 swapAmount = (_amount * _coefficient) / 10**18;
        uint256 exchangeAmount = _amount - swapAmount;
        if ((_coefficient / 10**18) == 1) {
            distibutionToExchange = false;
        }

        uint256 tokenSaleBalance = ODI.balanceOf(address(this));
        require(
            tokenSaleBalance >= _amount,
            "TokenSale::distribution: Amount more than token sale ODI balance"
        );

        ODI.transfer(address(SWAP), swapAmount);
        SWAP.transferFromTokenSale(_to, swapAmount);
        emit EDistribution(address(SWAP), _to, swapAmount);
        if (distibutionToExchange) {
            ODI.transfer(address(EXCHANGE), exchangeAmount);
            EXCHANGE.transferFromTokenSale(_to, exchangeAmount);
            emit EDistribution(address(EXCHANGE), _to, exchangeAmount);
        }
    }

    function setODIContract(address _odi) external onlyOwner {
        ODI = IERC20(_odi);
    }

    function setSWAPContract(address _swap) external onlyOwner {
        SWAP = ISWAP(_swap);
    }

    function setExchangeContract(address _exchange) external onlyOwner {
        EXCHANGE = IEXCHANGE(_exchange);
    }
}
