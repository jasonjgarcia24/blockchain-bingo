// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

library LibScheduler {
    function scheduler(uint256 _duration) public view returns (uint256) {
        uint256 _blockNumber = block.number + _duration;
        uint256 _stopBlockstamp = _blockNumber;
        uint256 _blocksPerMinute = 5;

        return _stopBlockstamp * _blocksPerMinute;
    }
}
