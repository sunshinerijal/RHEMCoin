# Contract Overview

## Token
- **RhesusMacaqueCoin.sol**: ERC20 token (`RHEM`) with 1B cap, snapshot voting, 0.5% burn fee, 0.25% dev fee, Merkle airdrop, DAO governance.

## Marketplace
- **NFTMarketplaceCore.sol**: Core NFT marketplace for minting, listing, purchasing, staking; uses `RHEM`.
- **NFTMarketplaceStorage.sol**: Storage structures and modifiers for `NFTMarketplaceCore`.
- **NFTMarketplaceEvents.sol**: Events for marketplace actions.
- **NFTMarketplaceRHEM.sol**: Marketplace with 1 `RHEM` listing fee, 0.75% sale fee.
- **NFTMarketplaceReferral.sol**: Marketplace with 0.01 ETH listing fee, 5% referral fee.

## Staking
- **NFTStaking.sol**: Stakes NFTs for `RHEM` rewards.

## Governance
- **RhesusMacaqueVoting.sol**: Voting for DAO proposals.
- **Governance.sol**: Manages voting, timelock, and liquidity locker addresses.
- **TimelockVault.sol**: Locks tokens with DAO control.

## Liquidity
- **RHEMSwap.sol**: Liquidity pool for `RHEM` swaps, upgradeable.
- **LiquidityLocker.sol**: Locks DEX liquidity tokens.

## Bridge
- **NFTBridge.sol**: Cross-chain NFT bridging.
- **CrossChainBridge.sol**: Cross-chain `RHEM` token bridging.

## Airdrop
- **MerkleAirdropNFT.sol**: NFT airdrop via Merkle proof.

## Proxy
- **ERC1967Proxy.sol**: EIP-1967 proxy for upgrades.
- **ProxyAdmin.sol**: Manages proxy upgrades.

## Platform
- **RHEMPlatform.sol**: Central hub for registering and initializing modules
- **(e.g., NFT marketplace, staking, airdrop), managed by DAO with multisig, pausability, timelock checks, and token fee collection.