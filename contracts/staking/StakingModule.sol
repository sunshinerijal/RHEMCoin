// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IERC20.sol";

contract StakingModule is ReentrancyGuard, Pausable, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");

    IERC20 public immutable rhemToken;
    address public immutable multiSigOwner;
    address public rewardPool;
    uint256 public totalStaked;

    uint256[] public lockPeriods = [
        7 * 86400,   // 7 days
        14 * 86400,  // 14 days
        30 * 86400,  // 30 days
        30 * 86400,  // 1 month
        3 * 30 * 86400, // 3 months
        6 * 30 * 86400, // 6 months
        9 * 30 * 86400, // 9 months
        12 * 30 * 86400 // 12 months
    ];
    mapping(uint256 => uint256) public rewardMultipliers;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriodIndex;
        uint256 accumulatedRewards;
    }
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalUserStaked;

    event Staked(address indexed user, uint256 amount, uint256 lockPeriodIndex, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 rewards, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardPoolUpdated(address indexed newPool);
    event RewardMultiplierUpdated(uint256 indexed lockPeriodIndex, uint256 multiplier);

    constructor(address _rhemToken, address _multiSigOwner) {
        require(_rhemToken != address(0) && _multiSigOwner != address(0), "Invalid address");
        rhemToken = IERC20(_rhemToken);
        multiSigOwner = _multiSigOwner;
        _setupRole(OWNER_ROLE, _multiSigOwner);
        _setupRole(REWARD_MANAGER_ROLE, _multiSigOwner);

        rewardMultipliers[0] = 100; // 7 days: 1x
        rewardMultipliers[1] = 110; // 14 days: 1.1x
        rewardMultipliers[2] = 120; // 30 days: 1.2x
        rewardMultipliers[3] = 130; // 1 month: 1.3x
        rewardMultipliers[4] = 150; // 3 months: 1.5x
        rewardMultipliers[5] = 180; // 6 months: 1.8x
        rewardMultipliers[6] = 200; // 9 months: 2x
        rewardMultipliers[7] = 250; // 12 months: 2.5x
    }

    function stake(uint256 amount, uint256 lockPeriodIndex) external nonReentrant whenNotPaused {
        require(amount > 0, "Invalid amount");
        require(lockPeriodIndex < lockPeriods.length, "Invalid lock period");
        require(rhemToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: block.timestamp,
            lockPeriodIndex: lockPeriodIndex,
            accumulatedRewards: 0
        }));
        totalStaked += amount;
        totalUserStaked[msg.sender] += amount;

        emit Staked(msg.sender, amount, lockPeriodIndex, block.timestamp);
    }

    function unstake(uint256 stakeIndex) external nonReentrant whenNotPaused {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(block.timestamp >= userStake.startTime + lockPeriods[userStake.lockPeriodIndex], "Still locked");

        uint256 amount = userStake.amount;
        uint256 rewards = calculateRewards(msg.sender, stakeIndex);
        require(amount > 0, "No stake");

        totalStaked -= amount;
        totalUserStaked[msg.sender] -= amount;
        userStake.amount = 0;
        userStake.accumulatedRewards = 0;

        require(rhemToken.transfer(msg.sender, amount), "Transfer failed");
        if (rewards > 0 && rewardPool != address(0)) {
            require(IERC20(rhemToken).transferFrom(rewardPool, msg.sender, rewards), "Reward transfer failed");
            emit RewardsClaimed(msg.sender, rewards);
        }

        emit Unstaked(msg.sender, amount, rewards, block.timestamp);
    }

    function calculateRewards(address user, uint256 stakeIndex) public view returns (uint256) {
        Stake storage userStake = stakes[user][stakeIndex];
        if (userStake.amount == 0) return userStake.accumulatedRewards;

        uint256 timeElapsed = block.timestamp - userStake.startTime;
        uint256 baseReward = userStake.amount * timeElapsed / 1 days;
        uint256 multiplier = rewardMultipliers[userStake.lockPeriodIndex];
        return userStake.accumulatedRewards + (baseReward * multiplier / 100);
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function setRewardPool(address _rewardPool) external onlyRole(OWNER_ROLE) {
        require(_rewardPool != address(0), "Invalid address");
        rewardPool = _rewardPool;
        emit RewardPoolUpdated(_rewardPool);
    }

    function setRewardMultiplier(uint256 lockPeriodIndex, uint256 multiplier) external onlyRole(REWARD_MANAGER_ROLE) {
        require(lockPeriodIndex < lockPeriods.length, "Invalid lock period");
        require(multiplier >= 100, "Multiplier too low");
        rewardMultipliers[lockPeriodIndex] = multiplier;
        emit RewardMultiplierUpdated(lockPeriodIndex, multiplier);
    }
}