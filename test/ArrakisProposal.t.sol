// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {MultiSendCallOnly} from "safe-contracts/libraries/MultiSendCallOnly.sol";

import {ForgeHelper} from "./utils/ForgeHelper.sol";
import {ForkHelper} from "./utils/ForkHelper.sol";
import {AddressLookup} from "./utils/AddressLookup.sol";

import "forge-std/StdJson.sol";
import "forge-std/console.sol";

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

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        Operation operation;
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
    // 3. mainnet approval of NEXT to vault
    // 4. deposit NEXT into vault
    // 5. mainnet approval of NEXT to connext
    // 6. arbitrum approval of NEXT to terms (via xcall)
    // 7. arbitrum increaseLiquidity on terms (via xcall)
    uint256 public NUMBER_TRANSACTIONS = 7;

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
    // TODO: should submit via multisend to simulate bundling of transactions
    function utils_generateMultisendTransactions() public view returns (bytes memory _transactions) {
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
            // No way to check if data is null in json, this will revert if data is null
            // TODO: add support to automatically generate data if its null
            bytes memory data = json.readBytes(string.concat(baseJsonPath, ".data"));

            // Add to transactions
            _transactions = bytes.concat(
                _transactions,
                abi.encodePacked(
                    uint8(0), // type: call
                    to, // to
                    value, // value
                    data.length, // data length
                    data // data
                )
            );
        }
    }

    function utils_generateTransactions() public view returns (Transaction[] memory _transactions) {
        // Generate executable from `arrakis-transactions.json`
        string memory path = string.concat(
            vm.projectRoot(),
            TRANSACTIONS_PATH
        );

        string memory json = vm.readFile(path);

        // Generate the bytes of the multisend transactions
        _transactions = new Transaction[](NUMBER_TRANSACTIONS);
        for (uint256 i; i < NUMBER_TRANSACTIONS; i++) {
            string memory baseJsonPath = string.concat(".transactions[", i.toString(), "]");
            address to = json.readAddress(string.concat(baseJsonPath, ".to"));
            uint256 value = json.readUint(string.concat(baseJsonPath, ".value"));
            // No way to check if data is null in json, this will revert if data is null
            // TODO: add support to automatically generate data if its null
            bytes memory data = json.readBytes(string.concat(baseJsonPath, ".data"));

            // Add to transactions
            _transactions[i] = Transaction({
                to: to,
                value: value,
                data: data,
                operation: Operation.Call
            });
        }
    }

    // ================== Tests ==================
    function test_executableShouldPass() public {
        // Generate the multisend transactions
        // bytes memory transactions = utils_generateMultisendTransactions();
        Transaction[] memory transactions = utils_generateTransactions();

        // Select and prep fork
        vm.selectFork(FORK_HELPER.forkIdsByChain(1));
        address caller = AddressLookup.getConnextDao(1);
        vm.makePersistent(caller);

        // Submit the transactions
        // NOTE: This assumes signatures will be valid, and the batching of these transactions
        // will be valid. Simply pranks and calls each function in a loop as DAO.
        for (uint256 i; i < transactions.length; i++) {
            // Send tx
            vm.prank(caller);
            (bool success,) = transactions[i].to.call{value: transactions[i].value}(transactions[i].data);
            assertTrue(success, string.concat("!success @ ", i.toString()));
        }

        // Process arbitrum xcall for `approval`

        // Process arbitrum xcall for `increaseLiquidity`

        // Assert final balance changes
    }
}