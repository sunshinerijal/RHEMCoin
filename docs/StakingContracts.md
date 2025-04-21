# Contracts Documentation

## Platform
- **RHEMPlatform.sol**: Central hub for module registration and marketplace initialization, with multisig, pausability, account freezing, and whitelisting. Features NatSpec documentation, custom errors (PlatformPaused, AccountRestricted), and module type validation.

## Token
- **RhesusMacaqueCoin.sol**: RHEM token (ERC-20) with initial supply and burn functionality.

## Marketplace
- **NFTMarketplaceCore.sol**: Core logic for NFT listing, buying, and selling.
- **NFTMarketplaceStorage.sol**: Storage for marketplace data.
- **NFTMarketplaceEvents.sol**: Event definitions for marketplace interactions.
- **NFTMarketplaceRHEM.sol**: Handles RHEM token payments.
- **NFTMarketplaceReferral.sol**: Manages referral rewards.

## Staking
- **NFTStaking.sol**: Enables NFT staking for rewards.
- **StakingModule.sol**: Manages staking logic, integrable with RHEMPlatform.
- **RewardPool.sol**: Distributes staking rewards.

## Airdrop
- **MerkleAirdropNFT.sol**: Facilitates NFT airdrops using Merkle trees.

## Bridge
- **CrossChainBridge.sol**: Supports cross-chain token/NFT transfers.
- **NFTBridge.sol**: Specific to NFT cross-chain bridging.

## Swap
- **RHEMSwap.sol**: Provides liquidity pools for RHEM trading.
- **LiquidityLocker.sol**: Locks liquidity for RHEMSwap.

## Voting
- **RhesusMacaqueVoting.sol**: Governance voting for RHEM ecosystem.

## Governance
- **Governance.sol**: Core governance logic.

## Timelock
- **TimelockVault.sol**: Implements timelock for delayed executions.

## Trading
- **TradingModule.sol**: Enables RHEM token trading, 
   tracks trade history, and supports analytics, integrated 
   with RHEMPlatform.