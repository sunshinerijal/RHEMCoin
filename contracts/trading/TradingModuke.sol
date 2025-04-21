// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRHEMToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

interface IRHEMPlatform {
    function frozenAccounts(address) external view returns (bool);
    function transferWhitelist(address) external view returns (bool);
    function transferWhitelistEnabled() external view returns (bool);
}

contract TradingModule {
    address public immutable multiSigOwner;
    address public immutable rhemToken;
    address public immutable platform;
    address public devWallet;
    mapping(address => uint256) public tradeVolume;
    mapping(address => Trade[]) public tradeHistory;

    struct Trade {
        uint256 amount;
        uint256 price;
        uint256 timestamp;
        bool isBuy;
    }

    event TradeExecuted(address indexed user, uint256 amount, uint256 price, bool isBuy, uint256 timestamp);
    event DevWalletUpdated(address indexed newDevWallet);

    constructor(address _multiSigOwner, address _rhemToken, address _platform, address _devWallet) {
        require(_multiSigOwner != address(0) && _rhemToken != address(0) && _platform != address(0), "Invalid address");
        multiSigOwner = _multiSigOwner;
        rhemToken = _rhemToken;
        platform = _platform;
        devWallet = _devWallet;
    }

    function executeTrade(uint256 amount, uint256 price, bool isBuy) external {
        require(amount > 0 && price > 0, "Invalid input");
        require(!IRHEMPlatform(platform).frozenAccounts(msg.sender), "Account frozen");
        require(!IRHEMPlatform(platform).transferWhitelistEnabled() || IRHEMPlatform(platform).transferWhitelist(msg.sender), "Not whitelisted");
        uint256 fee = amount / 100; // 1% fee
        require(IRHEMToken(rhemToken).transferFrom(msg.sender, devWallet, fee), "Fee transfer failed");
        tradeVolume[msg.sender] += amount;
        tradeHistory[msg.sender].push(Trade(amount, price, block.timestamp, isBuy));
        emit TradeExecuted(msg.sender, amount, price, isBuy, block.timestamp);
    }

    function getTradeHistory(address user) external view returns (Trade[] memory) {
        return tradeHistory[user];
    }

    function updateDevWallet(address newDevWallet) external {
        require(msg.sender == multiSigOwner, "Not owner");
        require(newDevWallet != address(0), "Invalid address");
        devWallet = newDevWallet;
        emit DevWalletUpdated(newDevWallet);
    }
}