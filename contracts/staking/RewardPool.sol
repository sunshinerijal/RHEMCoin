// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IERC20.sol";

contract RewardPool is AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    IERC20 public immutable rhemToken;
    address public stakingModule;

    event Funded(address indexed funder, uint256 amount);
    event StakingModuleUpdated(address indexed newModule);

    constructor(address _rhemToken, address _multiSigOwner) {
        require(_rhemToken != address(0) && _multiSigOwner != address(0), "Invalid address");
        rhemToken = IERC20(_rhemToken);
        _setupRole(OWNER_ROLE, _multiSigOwner);
    }

    function fund(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(rhemToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Funded(msg.sender, amount);
    }

    function setStakingModule(address _stakingModule) external onlyRole(OWNER_ROLE) {
        require(_stakingModule != address(0), "Invalid address");
        stakingModule = _stakingModule;
        emit StakingModuleUpdated(_stakingModule);
    }

    function approveForStaking(uint256 amount) external onlyRole(OWNER_ROLE) {
        require(stakingModule != address(0), "Staking module not set");
        require(rhemToken.approve(stakingModule, amount), "Approve failed");
    }
}