// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Inline IERC20 interface
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LiquidityLocker {
    address public token;
    address public dao;

    struct Lock {
        address locker;
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    mapping(address => bool) public hasLocked;
    uint256 public totalLocked;

    event TokensLocked(address indexed locker, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed locker, uint256 amount);
    event LockDeleted(address indexed locker, uint256 amount);
    event EmergencyUnlock(address indexed locker, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    constructor(address _token, address _dao) {
        require(_token != address(0), "Invalid token address");
        require(_dao != address(0), "Invalid DAO address");
        token = _token;
        dao = _dao;
    }

    function lockLiquidity(address from, uint256 amount, address dex, uint256 unlockTime) external onlyDAO {
        require(amount > 0, "Zero amount");
        require(unlockTime > block.timestamp + 1 days, "Unlock time too soon");
        require(!hasLocked[from], "Locker already has a lock"); // Check for existing lock on locker
        require(!hasLocked[dex], "DEX already locked"); // Check for existing lock on DEX

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        (bool success) = IERC20(token).transferFrom(from, address(this), amount);
        require(success, "Transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter == balanceBefore + amount, "Transfer amount mismatch");

        locks[dex] = Lock(from, amount, unlockTime);
        hasLocked[dex] = true;
        totalLocked += amount;

        emit TokensLocked(from, amount, unlockTime);
    }

    function release(address dex) external onlyDAO {
        Lock storage lock = locks[dex];
        require(lock.amount > 0, "Nothing locked");
        require(block.timestamp >= lock.unlockTime, "Still locked");

        uint256 amount = lock.amount;
        address to = lock.locker;

        delete locks[dex];
        delete hasLocked[dex];
        totalLocked -= amount;

        uint256 balanceBefore = IERC20(token).balanceOf(to);
        (bool success) = IERC20(token).transfer(to, amount);
        require(success, "Transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceAfter == balanceBefore + amount, "Transfer amount mismatch");

        emit TokensUnlocked(to, amount);
        emit LockDeleted(to, amount);
    }

    function emergencyUnlock(address dex) external onlyDAO {
        Lock storage lock = locks[dex];
        require(lock.amount > 0, "Nothing locked");

        uint256 amount = lock.amount;
        address to = lock.locker;

        delete locks[dex];
        delete hasLocked[dex];
        totalLocked -= amount;

        uint256 balanceBefore = IERC20(token).balanceOf(to);
        (bool success) = IERC20(token).transfer(to, amount);
        require(success, "Emergency transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceAfter == balanceBefore + amount, "Emergency transfer amount mismatch");

        emit EmergencyUnlock(to, amount);
        emit LockDeleted(to, amount);
    }

    function getLock(address dex) external view returns (Lock memory) {
        return locks[dex];
    }

    function isLocked(address dex) external view returns (bool) {
        return hasLocked[dex];
    }
}