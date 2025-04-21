// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title RHEMPlatform - Central hub for RHEM ecosystem module management
/// @notice Manages module registration, marketplace initialization, and platform fees with multisig governance, pausability, account freezing, and whitelisting
/// @dev Dependency-free contract using custom role-based access control and interfaces for RHEM token, marketplace, and timelock
contract RHEMPlatform {
    // --- State Variables ---

    /// @notice Role identifier for multisig owner (admin)
    bytes32 public constant OWNER_ROLE = keccak256(abi.encodePacked("OWNER_ROLE"));
    /// @notice Role identifier for DAO governance
    bytes32 public constant DAO_ROLE = keccak256(abi.encodePacked("DAO_ROLE"));
    /// @notice Mapping of roles to addresses (role => account => hasRole)
    mapping(bytes32 => mapping(address => bool)) private _roles;
    /// @notice Multisig owner address, immutable for security
    address public immutable multiSigOwner;
    /// @notice Platform pause state (true = paused)
    bool public paused;
    /// @notice Mapping of frozen accounts (address => isFrozen)
    mapping(address => bool) public frozenAccounts;
    /// @notice Flag for enabling/disabling transfer whitelist
    bool public transferWhitelistEnabled;
    /// @notice Mapping of whitelisted addresses (address => isWhitelisted)
    mapping(address => bool) public transferWhitelist;
    /// @notice RHEM token contract address, immutable
    address public immutable rhemToken;
    /// @notice Timelock contract address, immutable
    address public immutable timelock;
    /// @notice Developer wallet for fee collection
    address public devWallet;
    /// @notice Burn address for fee burning
    address public burnAddress;
    /// @notice DAO address for governance
    address public dao;
    /// @notice Mapping of module types to their contract addresses
    mapping(string => address) public registeredModules;

    // --- Custom Errors ---

    /// @notice Thrown when an address is zero or invalid
    error InvalidAddress();
    /// @notice Thrown when caller lacks required role
    error AccessDenied();
    /// @notice Thrown when contract is paused
    error PlatformPaused();
    /// @notice Thrown when account is frozen
    error AccountRestricted();
    /// @notice Thrown when account is not whitelisted
    error NotWhitelisted();
    /// @notice Thrown when timelock operation is not ready
    error TimelockNotReady();
    /// @notice Thrown when timelock operation is already executed
    error TimelockExecuted();
    /// @notice Thrown when module type is empty
    error InvalidModuleType();
    /// @notice Thrown when amount is zero
    error InvalidAmount();

    // --- Events ---

    /// @notice Emitted when a module is registered
    event ModuleRegistered(string moduleType, address indexed moduleAddress);
    /// @notice Emitted when a marketplace is initialized
    event MarketplaceInitialized(address indexed marketplace, address indexed dao);
    /// @notice Emitted when platform addresses are updated
    event AddressesUpdated(address indexed devWallet, address indexed burnAddress, address indexed dao);
    /// @notice Emitted when a platform fee is collected
    event PlatformFeeCollected(address indexed user, uint256 amount);
    /// @notice Emitted when the platform is paused
    event Paused(uint256 timestamp);
    /// @notice Emitted when the platform is unpaused
    event Unpaused(uint256 timestamp);
    /// @notice Emitted when an account is frozen
    event AccountFrozen(address indexed account, uint256 timestamp);
    /// @notice Emitted when an account is unfrozen
    event AccountUnfrozen(address indexed account, uint256 timestamp);
    /// @notice Emitted when whitelist is enabled
    event WhitelistEnabled(uint256 timestamp);
    /// @notice Emitted when whitelist is disabled
    event WhitelistDisabled(uint256 timestamp);
    /// @notice Emitted when whitelist status is updated
    event WhitelistUpdated(address indexed account, bool status, uint256 timestamp);
    /// @notice Emitted when a role is granted
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    // --- Modifiers ---

    /// @notice Restricts function to callers with specified role
    /// @param role The role to check
    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) revert AccessDenied();
        _;
    }

    /// @notice Restricts function to when contract is not paused
    modifier whenNotPaused() {
        if (paused) revert PlatformPaused();
        _;
    }

    // --- Constructor ---

    /// @notice Initializes the platform with governance and token settings
    /// @param _dao DAO address for governance
    /// @param _rhemToken RHEM token contract address
    /// @param _timelock Timelock contract address
    /// @param _devWallet Developer wallet for fees
    /// @param _burnAddress Burn address for fees
    /// @param _multiSigOwner Multisig owner address
    constructor(
        address _dao,
        address _rhemToken,
        address _timelock,
        address _devWallet,
        address _burnAddress,
        address _multiSigOwner
    ) {
        if (_dao == address(0) || _rhemToken == address(0) || _timelock == address(0) || _devWallet == address(0) || _burnAddress == address(0))
            revert InvalidAddress();
        if (_multiSigOwner == address(0)) revert InvalidAddress();
        rhemToken = _rhemToken;
        timelock = _timelock;
        dao = _dao;
        devWallet = _devWallet;
        burnAddress = _burnAddress;
        multiSigOwner = _multiSigOwner;
        paused = false;
        transferWhitelistEnabled = false;
        _roles[OWNER_ROLE][_multiSigOwner] = true;
        emit RoleGranted(OWNER_ROLE, _multiSigOwner, msg.sender);
        _roles[DAO_ROLE][_dao] = true;
        emit RoleGranted(DAO_ROLE, _dao, msg.sender);
    }

    // --- Access Control ---

    /// @notice Checks if an account has a specific role
    /// @param role The role to check
    /// @param account The account to check
    /// @return True if the account has the role
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /// @notice Grants a role to an account (internal)
    /// @param role The role to grant
    /// @param account The account to grant the role to
    function grantRole(bytes32 role, address account) internal {
        if (account == address(0)) revert InvalidAddress();
        _roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    // --- Pausability ---

    /// @notice Pauses the platform, restricting actions
    function pause() external onlyRole(OWNER_ROLE) {
        paused = true;
        emit Paused(block.timestamp);
    }

    /// @notice Unpauses the platform, allowing actions
    function unpause() external onlyRole(OWNER_ROLE) {
        paused = false;
        emit Unpaused(block.timestamp);
    }

    // --- Account Freezing ---

    /// @notice Freezes an account, preventing actions
    /// @param account The account to freeze
    function freezeAccount(address account) external onlyRole(OWNER_ROLE) {
        frozenAccounts[account] = true;
        emit AccountFrozen(account, block.timestamp);
    }

    /// @notice Unfreezes an account, allowing actions
    /// @param account The account to unfreeze
    function unfreezeAccount(address account) external onlyRole(OWNER_ROLE) {
        frozenAccounts[account] = false;
        emit AccountUnfrozen(account, block.timestamp);
    }

    // --- Whitelisting ---

    /// @notice Enables the transfer whitelist
    function enableWhitelist() external onlyRole(OWNER_ROLE) {
        transferWhitelistEnabled = true;
        emit WhitelistEnabled(block.timestamp);
    }

    /// @notice Disables the transfer whitelist
    function disableWhitelist() external onlyRole(OWNER_ROLE) {
        transferWhitelistEnabled = false;
        emit WhitelistDisabled(block.timestamp);
    }

    /// @notice Updates whitelist status for an account
    /// @param account The account to update
    /// @param status True to whitelist, false to remove
    function updateWhitelist(address account, bool status) external onlyRole(OWNER_ROLE) {
        transferWhitelist[account] = status;
        emit WhitelistUpdated(account, status, block.timestamp);
    }

    // --- Core Functions ---

    /// @notice Registers a module with the platform
    /// @param moduleType The type of module (e.g., "Trading", "Staking")
    /// @param moduleAddress The module contract address
    /// @param timelockId The timelock operation ID
    function registerModule(string calldata moduleType, address moduleAddress, bytes32 timelockId) external whenNotPaused onlyRole(DAO_ROLE) {
        if (bytes(moduleType).length == 0) revert InvalidModuleType();
        if (moduleAddress == address(0)) revert InvalidAddress();
        if (frozenAccounts[msg.sender]) revert AccountRestricted();
        if (transferWhitelistEnabled && !transferWhitelist[msg.sender]) revert NotWhitelisted();
        if (!ITimelock(timelock).isOperationReady(timelockId)) revert TimelockNotReady();
        if (ITimelock(timelock).isOperationDone(timelockId)) revert TimelockExecuted();
        registeredModules[moduleType] = moduleAddress;
        emit ModuleRegistered(moduleType, moduleAddress);
    }

    /// @notice Initializes a marketplace with platform settings
    /// @param marketplace The marketplace contract address
    /// @param timelockId The timelock operation ID
    function initializeMarketplace(address marketplace, bytes32 timelockId) external whenNotPaused onlyRole(DAO_ROLE) {
        if (marketplace == address(0)) revert InvalidAddress();
        if (frozenAccounts[msg.sender]) revert AccountRestricted();
        if (transferWhitelistEnabled && !transferWhitelist[msg.sender]) revert NotWhitelisted();
        if (!ITimelock(timelock).isOperationReady(timelockId)) revert TimelockNotReady();
        if (ITimelock(timelock).isOperationDone(timelockId)) revert TimelockExecuted();
        INFTMarketplace(marketplace).initializeMarketplace(dao, devWallet, rhemToken, burnAddress, timelock);
        registeredModules["NFTMarketplace"] = marketplace;
        emit MarketplaceInitialized(marketplace, dao);
    }

    /// @notice Collects platform fees, splitting between devWallet and burnAddress
    /// @param user The user to collect fees from
    /// @param amount The fee amount
    function collectPlatformFee(address user, uint256 amount) external whenNotPaused onlyRole(DAO_ROLE) {
        if (amount == 0) revert InvalidAmount();
        if (frozenAccounts[user]) revert AccountRestricted();
        if (transferWhitelistEnabled && !transferWhitelist[user]) revert NotWhitelisted();
        if (!IRHEMToken(rhemToken).transferFrom(user, devWallet, amount / 2)) revert("Fee transfer failed");
        if (!IRHEMToken(rhemToken).transferFrom(user, burnAddress, amount / 2)) revert("Burn transfer failed");
        emit PlatformFeeCollected(user, amount);
    }

    /// @notice Updates platform addresses with timelock
    /// @param _dao New DAO address (optional)
    /// @param _devWallet New developer wallet (optional)
    /// @param _burnAddress New burn address (optional)
    /// @param timelockId The timelock operation ID
    function updateAddresses(address _dao, address _devWallet, address _burnAddress, bytes32 timelockId) external whenNotPaused onlyRole(OWNER_ROLE) {
        if (!ITimelock(timelock).isOperationReady(timelockId)) revert TimelockNotReady();
        if (ITimelock(timelock).isOperationDone(timelockId)) revert TimelockExecuted();
        if (_dao != address(0)) {
            grantRole(DAO_ROLE, _dao);
            dao = _dao;
        }
        if (_devWallet != address(0)) devWallet = _devWallet;
        if (_burnAddress != address(0)) burnAddress = _burnAddress;
        emit AddressesUpdated(_devWallet, _burnAddress, _dao);
    }

    /// @notice Retrieves the address of a registered module
    /// @param moduleType The type of module
    /// @return The module contract address
    function getModule(string calldata moduleType) external view returns (address) {
        if (bytes(moduleType).length == 0) revert InvalidModuleType();
        return registeredModules[moduleType];
    }
}

// --- Interfaces ---
interface IRHEMToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

interface INFTMarketplace {
    function initializeMarketplace(address dao, address devWallet, address token, address burnAddress, address timelock) external;
}

interface ITimelock {
    function isOperationPending(bytes32 id) external view returns (bool);
    function isOperationReady(bytes32 id) external view returns (bool);
    function isOperationDone(bytes32 id) external view returns (bool);
}