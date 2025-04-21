// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
interface INFTMarketplace {
    function initializeMarketplace(address dao, address devWallet, address token, address burnAddress, address timelock) external;
}