// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {MultiSendCallOnly} from "safe-contracts/libraries/MultiSendCallOnly.sol";

import {ForgeHelper} from "./utils/ForgeHelper.sol";
import {ForkHelper} from "./utils/ForkHelper.sol";
import {AddressLookup} from "./utils/AddressLookup.sol";

import "forge-std/StdJson.sol";

// Addresses ----

// 0xB041f628e961598af9874BCf30CC865f67fad3EE - PALMTerms address (on both mainnet and arbitrum)

// 0x3395d368c76c5db0e6235c2d43b9b0393fe40080 - mainnet Arrakis vault address

// 0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29 - arbitrum Arrakis vault address

// 0xFE67A4450907459c3e1FFf623aA927dD4e28c67a - mainnet NEXT token (token1 on mainnet vault)

// 0x58b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e8 - arbitrum NEXT token (token0 on arb vault)

// --------

contract ArrakisProposal is ForgeHelper {
     enum Operation {
        Call,
        DelegateCall
    }

    // ================== Libraries ==================
    using stdJson for string;
    using Strings for string;
    using Strings for uint256;


    // ================== Events ==================

    // ================== Structs ==================

    // ================== Storage ==================

    // MultisendCallOnly contract (same on arb and mainnet)
    address public MULTISEND = address(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);

    // Arrakis vault address
    address public ARRAKIS_MAINNET = address(0x3395D368C76C5dB0E6235c2d43b9b0393Fe40080);
    address public ARRAKIS_ARBITRUM = address(0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29);
    address public ARRAKIS_PALM_TERMS = address(0xB041f628e961598af9874BCf30CC865f67fad3EE);

    // Fork management utilities
    ForkHelper public FORK_HELPER;

    // Transactions path
    string public TRANSACTIONS_PATH = "/arrakis-transactions.json";

    // Number of transactions to execute in multisend data:
    // 1. mainnet approval of NEXT to terms
    // 2. mainnet increaseLiquidity on terms
    // 3. arbitrum approval of NEXT to terms (via xcall)
    // 4. arbitrum increaseLiquidity on terms (via xcall)
    uint256 public NUMBER_TRANSACTIONS = 4;

    // ================== Setup ==================

    function setUp() public {
        // Create the fork helper for mainnet and arbitrum
        uint256[] memory chains = new uint256[](2);
        chains[0] = 1;
        chains[1] = 42161;
        FORK_HELPER = new ForkHelper(chains);

        // Create the forks
        FORK_HELPER.utils_createForks();
        assertEq(FORK_HELPER.utils_getNetworksCount(), 2, "!forks");
    }

    // ================== Utils ==================
    function utils_generateMultisendTransactions() public returns (bytes memory _transactions) {
        // Generate executable from `arrakis-transactions.json`
        string memory path = string.concat(
            vm.projectRoot(),
            TRANSACTIONS_PATH
        );

        string memory json = vm.readFile(path);

        // Generate the bytes of the multisend transactions
        for (uint256 i; i < NUMBER_TRANSACTIONS; i++) {
            string memory baseJsonPath = string.concat(".transactions[", i.toString(), "]");
            address to = json.readAddress(string.concat(baseJsonPath, ".to"));
            uint256 value = json.readUint(string.concat(baseJsonPath, ".value"));
            bytes memory data = json.readBytes(string.concat(baseJsonPath, ".data"));
            // TODO: add support to automatically generate data if its null
            require(data.length > 0, "!data");
            _transactions = bytes.concat(
                _transactions,
                abi.encodePacked(
                    uint8(1), // type: delegatecall
                    to, // to
                    value, // value
                    data.length, // data length
                    data // data
                )
            );
        }
    }

    // ================== Tests ==================
    function test_executableShouldPass() public {
        // Generate the multisend transactions
        bytes memory transactions = utils_generateMultisendTransactions();

        // Submit the multisend call
        vm.prank(AddressLookup.getConnextDao(1));
        MultiSendCallOnly(MULTISEND).multiSend(transactions);

        // // Generate the signatures

        // // Generate the payload to `execTransaction`
        // address to = MULTISEND;
        // uint256 value = 0;
        // bytes memory data = abi.encodeWithSignature(
        //     "multiSend(bytes)",
        //     transactions
        // );
        // Operation operation = Operation.Call;
        // uint256 safeTxGas = 300 wei;
        // uint256 baseGas = 300 wei;
        // uint256 gasPrice = 300 wei;
        // address gasToken = address(0);
        // address payable refundReceiver = payable(address(this));
        // bytes memory signatures;


        // executable should:
        // - approve vault to spend NEXT
        // - call `increaseLiquidity` on vault
        // - create an xcall to arbitrum that will transfer + approve NEXT to arbitrum
        // - create an xcall to arbitrum that will call `increaseLiquidity` on vault

        // These two should be executed via `execTransaction` on mainnet multisig

        // Process arbitrum message for approval

        // Process arbitrum message for `increaseLiquidity`

        // Assert final balance changes
    }
}