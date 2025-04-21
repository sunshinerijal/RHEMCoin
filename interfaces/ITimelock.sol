// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
interface ITimelock {
    function isOperationPending(bytes32 id) external view returns (bool);
    function isOperationReady(bytes32 id) external view returns (bool);
    function isOperationDone(bytes32 id) external view returns (bool);
}