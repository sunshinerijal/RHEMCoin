// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
interface IRHEMToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}