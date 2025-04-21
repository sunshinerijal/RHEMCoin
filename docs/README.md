# NFTMarketplaceProject

A decentralized NFT marketplace with RHEM token trading, staking, and governance.

## Setup
1. Install dependencies: `npm install`
2. Compile contracts: `npx hardhat compile`
3. Deploy: `npx hardhat run scripts/deploy.js --network localhost`
4. Run frontend: `cd frontend && npm start`

## Structure
- `contracts/`: Solidity contracts
- `interfaces/`: Contract interfaces
- `tests/`: Hardhat tests
- `scripts/`: Deployment scripts
- `frontend/`: React frontend
- `docs/`: Documentation

A decentralized ecosystem for NFTs and the RHEM token, featuring a marketplace, staking, governance, liquidity, cross-chain bridging, and airdrops.

## Project Structure

NFTMarketplaceProject/
├── contracts/
│   ├── token/
│   │   └── RhesusMacaqueCoin.sol
│   ├── marketplace/
│   │   ├── NFTMarketplaceCore.sol
│   │   ├── NFTMarketplaceStorage.sol
│   │   ├── NFTMarketplaceEvents.sol
│   │   ├── NFTMarketplaceRHEM.sol
│   │   └── NFTMarketplaceReferral.sol
│   ├── staking/
│   │   └── NFTStaking.sol
│   ├── governance/
│   │   ├── RhesusMacaqueVoting.sol
│   │   ├── Governance.sol
│   │   └── TimelockVault.sol
│   ├── liquidity/
│   │   ├── RHEMSwap.sol
│   │   └── LiquidityLocker.sol
│   ├── bridge/
│   │   ├── NFTBridge.sol
│   │   └── CrossChainBridge.sol
│   ├── airdrop/
│   │   └── MerkleAirdropNFT.sol
│   ├── proxy/
│   │   ├── ERC1967Proxy.sol
│   │   └── ProxyAdmin.sol
├── interfaces/
│   ├── IERC20.sol
│   ├── IERC721.sol
│   ├── IRHEMToken.sol
│   ├── IProxy.sol
├── tests/
│   ├── RhesusMacaqueCoin.test.js
│   ├── NFTMarketplaceCore.test.js
├── scripts/
│   ├── deploy.js
├── docs/
│   ├── README.md
│   ├── contracts.md



## Setup
1. Install dependencies: `npm install`
2. Compile contracts: `npx hardhat compile`
3. Run tests: `npx hardhat test`
4. Deploy contracts: `npx hardhat run scripts/deploy.js --network localhost`

## Contracts Overview
See [contracts.md](./contracts.md) for detailed contract descriptions.

## Requirements
- Node.js
- Hardhat
- Solidity 0.8.26