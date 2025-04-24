// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Inline IERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Inline Initializable
contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// Inline ReentrancyGuard
contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor() {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        require(_guardCounter == 1, "ReentrancyGuard: reentrant call");
        _guardCounter = 2;
        _;
        _guardCounter = 1;
    }
}

// Inline Ownable2Step
contract Ownable2Step is Initializable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    function acceptOwnership() public {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

contract RHEMSwap is Initializable, Ownable2Step, ReentrancyGuard {
    address public token;
    address public governanceContract;
    address public poolToken;
    uint256 public liquidity;

    uint256 public constant MAX_AMOUNT = type(uint256).max / 1e18; // Prevent overflow
    uint256 public constant MIN_AMOUNT = 1e6; // Minimum swap/liquidity amount (e.g., 0.000001 tokens)

    event LiquidityAdded(address indexed user, uint256 amount);
    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    modifier onlyDAO() {
        require(msg.sender == governanceContract, "Only DAO can call");
        _;
    }

    function initialize(address _token, address _governance, address _poolToken) public initializer {
        require(_token != address(0), "Invalid token address");
        require(_governance != address(0), "Invalid governance address");
        require(_poolToken != address(0), "Invalid pool token address");

        __Ownable2Step_init();

        token = _token;
        governanceContract = _governance;
        poolToken = _poolToken;

        transferOwnership(governanceContract);
    }

    function addLiquidity(uint256 amount) external nonReentrant {
        require(amount >= MIN_AMOUNT, "Amount below minimum");
        require(amount <= MAX_AMOUNT, "Amount exceeds maximum");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter == balanceBefore + amount, "Transfer amount mismatch");

        liquidity += amount;

        emit LiquidityAdded(msg.sender, amount);
    }

    function swap(uint256 amountIn) external nonReentrant {
        require(amountIn >= MIN_AMOUNT, "Amount below minimum");
        require(amountIn <= MAX_AMOUNT, "Amount exceeds maximum");
        require(IERC20(token).balanceOf(msg.sender) >= amountIn, "Insufficient token balance");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amountIn, "Insufficient allowance");
        require(IERC20(poolToken).balanceOf(address(this)) >= (amountIn * 99) / 100, "Insufficient pool token balance");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        bool sentIn = IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        require(sentIn, "Token transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter == balanceBefore + amountIn, "Transfer amount mismatch");

        uint256 amountOut = (amountIn * 99) / 100;

        uint256 poolBalanceBefore = IERC20(poolToken).balanceOf(msg.sender);
        bool sentOut = IERC20(poolToken).transfer(msg.sender, amountOut);
        require(sentOut, "Pool token transfer failed");
        uint256 poolBalanceAfter = IERC20(poolToken).balanceOf(msg.sender);
        require(poolBalanceAfter == poolBalanceBefore + amountOut, "Pool transfer amount mismatch");

        emit Swapped(msg.sender, amountIn, amountOut);
    }
}