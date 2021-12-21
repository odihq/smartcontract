// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract BaseSwapExchange is Ownable {
    mapping(address => uint256) internal _balances;

    mapping(address => bool) internal _allowedAccessTokenSale;

    IERC20 public ODI;

    constructor(address _odi) {
        ODI = IERC20(_odi);
    }

    event TransferFromTokenSale(
        address indexed from,
        address indexed to,
        uint256 value
    );

    modifier checkAllowedTokenSale() {
        require(
            _allowedAccessTokenSale[msg.sender] == true,
            "SwapExchange:: TokenSale is not allowed for request."
        );
        _;
    }

    function addAllowedTokenSale(address tokenSale) external onlyOwner {
        _allowedAccessTokenSale[tokenSale] = true;
    }

    function forbidTokenSale(address tokenSale) external onlyOwner {
        _allowedAccessTokenSale[tokenSale] = false;
    }

    function transferFromTokenSale(address _recipient, uint256 _amount)
        external
        checkAllowedTokenSale
    {
        _balances[_recipient] += _amount;
        emit TransferFromTokenSale(msg.sender, _recipient, _amount);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function _calcul(
        uint256 a,
        uint256 b,
        uint256 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }
}
