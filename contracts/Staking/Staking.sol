// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IEXCHANGE {
    function transferFromStaking(address recipient, uint256 amount) external;
}

contract Staking is Ownable {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp
    );
    event PayOutReward(
        address indexed user,
        uint256 reward,
        uint64 period,
        uint256 index,
        uint256 timestamp
    );
    event UnStake(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp
    );
    event Withdrawal(address indexed to, uint256 value);

    IERC20 public ODI;
    IEXCHANGE public EXCHANGE;

    uint256 public minimumODItoStaking = 0;
    uint256 private _rewardMonthlyPercent = 50000;
    uint256 private _unStakeMonthlyPercent = 100000;
    uint256 private _rewardFullPercent = 600000;
    uint256 private _incrementPeriod = 30 days;
    uint8 private _maxPeriod = 12;
    uint8 private _maxPeriodUnStake = 10;
    uint64 private _period = 365;
    uint64 private _unStakePeriod = 10;

    struct StakesData {
        uint256 index;
        bool isExist;
    }

    struct StakingSummaryForAdmin {
        address staker;
        Stake[] stakes;
    }

    struct StakingSummary {
        uint256 totalAmount;
        Stake[] stakes;
    }

    struct StakeholdersSummary {
        address[] stakers;
        Stake[][] stakes;
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 monthlyPercentage;
        uint256 periodPercentage;
        uint256 monthlyPercentageUnlock;
        uint256 timestamp;
        uint64 period;
        uint64 currentPeriod;
        uint256 unlockTime;
        uint64 periodUnStake;
        uint64 currentPeriodUnStake;
        uint256 unlockTimeUnStake;
        uint256 claimable;
        bool paidOut;
        bool rewardPaidOut;
        uint256 index;
    }

    struct Stakeholder {
        address user;
        Stake[] addressStakes;
    }

    Stakeholder[] internal stakeholders;

    mapping(address => StakesData) internal stakes;
    mapping(address => uint256) internal _balances;
    mapping(address => bool) internal _allowedAccessTokenSale;

    modifier checkAllowedTokenSale() {
        require(
            _allowedAccessTokenSale[msg.sender] == true,
            "SwapExchange:: TokenSale is not allowed for request."
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

    constructor(address _odi, address _exchange) {
        ODI = IERC20(_odi);
        EXCHANGE = IEXCHANGE(_exchange);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function stake(address _recipient, uint256 _amount)
        external
        checkAllowedTokenSale
    {
        require(
            _amount > 0 && _amount >= minimumODItoStaking,
            "Staking::stake: Unavailable number of ODI for stake"
        );
        _stake(_recipient, _amount);
    }

    function getSteakingWallets()
        external
        view
        onlyOwner
        returns (address[] memory, uint256[] memory)
    {
        address[] memory userWallets = new address[](stakeholders.length);
        uint256[] memory userBalances = new uint256[](stakeholders.length);

        for (uint256 i = 0; i < stakeholders.length; i++) {
            address item = stakeholders[i].user;
            uint256 balance = _balances[item];
            userWallets[i] = item;
            userBalances[i] = balance;
        }

        return (userWallets, userBalances);
    }

    function setODIContractAddress(address _address) external onlyOwner {
        ODI = IERC20(_address);
    }

    function setExchangeContractAddress(address _address) external onlyOwner {
        EXCHANGE = IEXCHANGE(_address);
    }

    function setMinimumODItoStaking(uint256 _amount) external onlyOwner {
        require(
            _amount >= 0,
            "Staking::setMinimumNumberODItoStaking: _amount cannot be lower than 0"
        );
        minimumODItoStaking = _amount;
    }

    function calculateStakeReward()
        external
        view
        onlyOwner
        returns (Stake[][] memory)
    {
        Stake[][] memory addressStakes = new Stake[][](stakeholders.length);

        uint256 addressStakesIndex = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            Stake[] memory _stakes = stakeholders[s].addressStakes;
            Stake[] memory appropriateStakes = new Stake[](_stakes.length);
            uint256 appStakeIndex = 0;
            for (uint256 st = 0; st < _stakes.length; st += 1) {
                if (_stakes.length > 0) {
                    Stake memory _currentStake = _stakes[st];

                    if (
                        block.timestamp > _currentStake.unlockTime &&
                        !_currentStake.paidOut
                    ) {
                        uint256 availableReward = _calculateStakeRewardForPeriod(
                                _currentStake
                            );
                        _currentStake.claimable = availableReward;
                        appropriateStakes[appStakeIndex] = _currentStake;
                        appStakeIndex += 1;
                    }
                }
            }

            if (
                appropriateStakes.length > 0 && appropriateStakes[0].amount > 0
            ) {
                addressStakes[addressStakesIndex] = appropriateStakes;
                addressStakesIndex += 1;
            }
        }

        return addressStakes;
    }

    function getStakeholders()
        external
        view
        onlyOwner
        returns (StakeholdersSummary memory)
    {
        address[] memory stakers = new address[](stakeholders.length);
        Stake[][] memory addressStakes = new Stake[][](stakeholders.length);
        uint256 userIndex = 0;
        uint256 stakesIndex = 0;

        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            uint256 stakeholdersLength = stakeholders[s].addressStakes.length;

            if (stakeholdersLength > 0) {
                Stake[] memory appropriateStakes = new Stake[](
                    stakeholdersLength
                );
                stakesIndex = 0;

                for (
                    uint256 st = 0;
                    st < stakeholders[s].addressStakes.length;
                    st += 1
                ) {
                    Stake memory currentStake = stakeholders[s].addressStakes[
                        st
                    ];
                    if (!currentStake.paidOut) {
                        uint256 availableReward = _calculateStakeRewardForPeriod(
                                currentStake
                            );
                        currentStake.claimable =
                            availableReward *
                            currentStake.currentPeriod;
                        appropriateStakes[stakesIndex] = currentStake;
                        stakesIndex += 1;
                    }
                }

                if (
                    appropriateStakes.length > 0 &&
                    appropriateStakes[0].amount != 0
                ) {
                    stakers[userIndex] = stakeholders[s].user;
                    addressStakes[userIndex] = appropriateStakes;
                    userIndex++;
                }
            }
        }
        StakeholdersSummary memory summary = StakeholdersSummary(
            stakers,
            addressStakes
        );
        return summary;
    }

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push(); // Make space for our new stakeholder
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker].index = userIndex;
        stakes[staker].isExist = true;

        return userIndex;
    }

    function _stake(address _recipient, uint256 _amount) internal {
        uint256 index;

        StakesData memory stakesData = stakes[_recipient];
        uint256 timestamp = block.timestamp;

        if (!stakesData.isExist) {
            index = _addStakeholder(_recipient);
        } else {
            index = stakesData.index;
        }

        uint256 lastIndexNumber = stakeholders[index].addressStakes.length;

        stakeholders[index].addressStakes.push(
            Stake(
                _recipient,
                _amount,
                _rewardMonthlyPercent,
                _rewardFullPercent,
                _unStakeMonthlyPercent,
                timestamp,
                _period,
                0,
                block.timestamp + _incrementPeriod,
                _unStakePeriod,
                0,
                block.timestamp + (_incrementPeriod * 13),
                0,
                false,
                false,
                lastIndexNumber
            )
        );

        _balances[_recipient] += _amount;

        emit Staked(_recipient, _amount, index, timestamp);
    }

    function _percentageFromNumber(uint256 _amount, uint256 _percent)
        internal
        pure
        returns (uint256)
    {
        return ((_amount * _percent) / 100) / (10**4);
    }

    function _calculateStakeRewardForPeriod(Stake memory _currentStake)
        internal
        pure
        returns (uint256)
    {
        uint256 _percent = _currentStake.monthlyPercentage;

        return _percentageFromNumber(_currentStake.amount, _percent);
    }

    function _calculateUnStakeForPeriod(Stake memory _currentStake)
        internal
        pure
        returns (uint256)
    {
        uint256 _precent = _currentStake.monthlyPercentageUnlock;
        return _percentageFromNumber(_currentStake.amount, _precent);
    }

    function payOutReward(address receiver, uint256 index) external onlyOwner {
        uint256 userIndex = stakes[receiver].index;
        Stake memory currentStake = stakeholders[userIndex].addressStakes[
            index
        ];

        uint256 reward = _calculateStakeRewardForPeriod(currentStake);
        require(
            currentStake.rewardPaidOut == false,
            "Staking::payOutReward: This staking reward has already been paid"
        );
        require(
            block.timestamp >= currentStake.unlockTime,
            "Staking::payOutReward: Can't pay reward"
        );

        stakeholders[userIndex].addressStakes[index].currentPeriod =
            currentStake.currentPeriod +
            1;
        stakeholders[userIndex]
            .addressStakes[index]
            .unlockTime += _incrementPeriod;

        if (currentStake.currentPeriod == _maxPeriod - 1) {
            stakeholders[userIndex].addressStakes[index].rewardPaidOut = true;
        }

        ODI.transfer(address(EXCHANGE), reward);
        EXCHANGE.transferFromStaking(receiver, reward);
        emit PayOutReward(
            receiver,
            reward,
            currentStake.currentPeriod + 1,
            index,
            block.timestamp
        );
    }

    function unStake(address receiver, uint256 index) external onlyOwner {
        uint256 userIndex = stakes[receiver].index;
        Stake memory currentStake = stakeholders[userIndex].addressStakes[
            index
        ];
        require(
            currentStake.paidOut == false && currentStake.rewardPaidOut == true,
            "Staking::Unstake: This staking has already been paid"
        );
        require(
            block.timestamp >= currentStake.unlockTimeUnStake,
            "Staking::Unstake: Can't pay unstake"
        );

        stakeholders[userIndex].addressStakes[index].currentPeriodUnStake =
            currentStake.currentPeriodUnStake +
            1;
        stakeholders[userIndex]
            .addressStakes[index]
            .unlockTimeUnStake += _incrementPeriod;

        if (currentStake.currentPeriodUnStake == _maxPeriodUnStake - 1) {
            stakeholders[userIndex].addressStakes[index].paidOut = true;
        }

        uint256 unStakeValue = _calculateUnStakeForPeriod(currentStake);

        _balances[receiver] -= unStakeValue;
        ODI.transfer(address(EXCHANGE), unStakeValue);
        EXCHANGE.transferFromStaking(receiver, unStakeValue);
        emit UnStake(receiver, unStakeValue, index, block.timestamp);
    }

    function withdrawal(address _to, uint256 _amount) external onlyOwner {
        require(
            ODI.balanceOf(address(this)) >= _amount,
            "Staking::withdrawal. Contract balance is not sufficient."
        );
        ODI.transfer(_to, _amount);
        emit Withdrawal(_to, _amount);
    }
}
