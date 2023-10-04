// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ForgeHelper} from "./utils/ForgeHelper.sol";
import {ForkHelper} from "./utils/ForkHelper.sol";

// Addresses ----

// 0xB041f628e961598af9874BCf30CC865f67fad3EE - PALMTerms address (on both mainnet and arbitrum)

// 0x3395d368c76c5db0e6235c2d43b9b0393fe40080 - mainnet Arrakis vault address

// 0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29 - arbitrum Arrakis vault address

// 0xFE67A4450907459c3e1FFf623aA927dD4e28c67a - mainnet NEXT token (token1 on mainnet vault)

// 0x58b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e8 - arbitrum NEXT token (token0 on arb vault)

// --------

contract ArrakisProposal is ForgeHelper {
    // ================== Libraries ==================

    // ================== Events ==================

    // ================== Structs ==================

    // ================== Storage ==================

    // Arrakis vault address
    address public ARRAKIS_MAINNET = address(0x3395D368C76C5dB0E6235c2d43b9b0393Fe40080);
    address public ARRAKIS_ARBITRUM = address(0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29);
    address public ARRAKIS_PALM_TERMS = address(0xB041f628e961598af9874BCf30CC865f67fad3EE);

    // Fork management utilities
    ForkHelper public FORK_HELPER;

    // ================== Setup ==================

    function setUp() public {
        // Create the fork helper for mainnet and arbitrum
        uint256[] memory chains = new uint256[](2);
        chains[0] = 1;
        chains[1] = 42161;
        FORK_HELPER = new ForkHelper(chains);

        // Create the forks
        FORK_HELPER.utils_createForks();
    }

    // ================== Utils ==================

    // ================== Tests ==================
    function test_executableShouldPass() public {
        assertEq(FORK_HELPER.utils_getNetworksCount(), 2, "!forks");

        // Generate executable from `arrakis-transactions.json`

        // executable should:
        // - approve vault to spend NEXT
        // - call `increaseLiquidity` on vault
        // - create an xcall to arbitrum that will transfer + approve NEXT to arbitrum
        // - create an xcall to arbitrum that will call `increaseLiquidity` on vault

        // These two should be proposed

        // `execTransaction` on mainnet multisig

        // Process arbitrum message

        // Assert final balance changes
    }
}