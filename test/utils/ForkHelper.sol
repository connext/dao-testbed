// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/utils/Strings.sol";

import {ForgeHelper} from "./ForgeHelper.sol";
import {ChainLookup} from "./ChainLookup.sol";

import "forge-std/console.sol";

/**
 * @notice A 'ForkHelper' used to initialize all the applicable forks (found in foundry.toml).
 *
 * @dev Can load fork info from two sources environment variables using the same keys found in
 * `.env.example`
 */
contract ForkHelper is ForgeHelper {
  // ============ Libraries ============
  using Strings for string;
  using Strings for uint256;

  // ============ Storage ============

  // All chain ids to fork
  uint256[] public NETWORK_IDS;

  // All blocks to fork from
  uint256[] public FORK_BLOCKS;

  // Chainid and fork lookups (provide reverse lookup so you can
  // find fork given id or chain)
  mapping(uint256 => uint256) public forkIdsByChain;
  mapping(uint256 => uint256) public chainsByForkId;

  // ============ Constructor ============
  constructor(uint256[] memory _networkIds, uint256[] memory _forkBlocks) {
    require(_networkIds.length == _forkBlocks.length, "!length");
    // Set all networks to fork
    for (uint256 i; i < _networkIds.length; i++) {
      NETWORK_IDS.push(_networkIds[i]);
      FORK_BLOCKS.push(_forkBlocks[i]);
    }
  }


  // ============ Utils ==================

  function utils_getNetworksCount() public view returns (uint256 _len) {
    _len = NETWORK_IDS.length;
  }

  /**
   * @notice Create a fork for each network
   */
  function utils_createForks() public {
    require(NETWORK_IDS.length > 0, "!networks");
    for (uint256 i; i < NETWORK_IDS.length; i++) {
      // create the fork
      uint256 forkId = vm.createSelectFork(vm.envString(ChainLookup.getRpcEnvName(NETWORK_IDS[i])), FORK_BLOCKS[i]);
      // update the mappings
      forkIdsByChain[block.chainid] = forkId;
      chainsByForkId[forkId] = block.chainid;
    }
  }

  /**
   * @notice Selects a fork given a chain
   */
  function utils_selectFork(uint256 chain) public returns (uint256 forkId) {
    // activate the fork
    forkId = forkIdsByChain[chain];
    vm.selectFork(forkId);
  }

  /**
   * @notice Rolls fork to a given timestamp
   */
  function utils_rollForkTo(uint256 timestamp) public {
    // get blocktime
    uint256 pre = block.timestamp;
    if (pre >= timestamp) {
      return;
    }
    require(pre < timestamp, "cannot rewind");
    uint256 warp = timestamp - block.timestamp;
    vm.rollFork(1 + block.number);
    uint256 blocktime = block.timestamp - pre;

    uint256 rolls = blocktime == 0 ? (warp * 3) / 2 : warp / blocktime;
    vm.rollFork(rolls + block.number);
    // ensure at timestamp
    uint256 step = (rolls * 3) / 2;
    while (block.timestamp < timestamp) {
      vm.rollFork(25 + step + block.number);
    }
  }
}
