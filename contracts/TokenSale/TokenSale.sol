// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../utils/address.sol";

interface ISTAKING {
    function stake(address _recipient, uint256 _amount) external;
}

contract TokenSale is Ownable {
    using Address for address;

    event EStaking(
        address indexed contractAddress,
        address indexed toWallet,
        uint256 amount
    );

    IERC20 public ODI;
    ISTAKING public STAKING;

    constructor(address _staking, address _odi) {
        STAKING = ISTAKING(_staking);
        ODI = IERC20(_odi);
    }

    function staking(uint256 _amount, address _to) external onlyOwner {
        uint256 stakingAmount = _amount;

        uint256 tokenSaleBalance = ODI.balanceOf(address(this));
        require(
            tokenSaleBalance >= stakingAmount,
            "TokenSale::staking: Amount more than token sale ODI balance"
        );

        ODI.transfer(address(STAKING), stakingAmount);
        STAKING.stake(_to, stakingAmount);
        emit EStaking(address(STAKING), _to, stakingAmount);
    }

    function setODIContract(address _odi) external onlyOwner {
        ODI = IERC20(_odi);
    }

    function setStakingContract(address _staking) external onlyOwner {
        STAKING = ISTAKING(_staking);
    }
}
