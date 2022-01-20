// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract BaseExchange is Ownable {
    mapping(address => uint256) internal _balances;

    mapping(address => bool) internal _allowedAccessTokenSale;

    IERC20 public ODI;

    constructor(address _odi) {
        ODI = IERC20(_odi);
    }

    event TransferFromStaking(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Withdrawal(address indexed to, uint256 value);

    modifier checkAllowedTokenSale() {
        require(
            _allowedAccessTokenSale[msg.sender] == true,
            "Exchange:: TokenSale is not allowed for request."
        );
        _;
    }

    function checkAccessTokenSale(address tokenSale)
        external
        view
        returns (bool)
    {
        return _allowedAccessTokenSale[tokenSale];
    }

    function addAllowedTokenSale(address tokenSale) external onlyOwner {
        _allowedAccessTokenSale[tokenSale] = true;
    }

    function forbidTokenSale(address tokenSale) external onlyOwner {
        _allowedAccessTokenSale[tokenSale] = false;
    }

    function transferFromStaking(address _recipient, uint256 _amount)
        external
        checkAllowedTokenSale
    {
        _balances[_recipient] += _amount;
        emit TransferFromStaking(msg.sender, _recipient, _amount);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function withdrawal(address _to, uint256 _amount) external onlyOwner {
        require(
            ODI.balanceOf(address(this)) >= _amount,
            "Exchange::withdrawal. Contract balance is not sufficient."
        );
        ODI.transfer(_to, _amount);
        emit Withdrawal(_to, _amount);
    }
}
