// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

interface IDatetime {
    function getResolvedAfter(uint timestamp) external pure returns(uint);
}

