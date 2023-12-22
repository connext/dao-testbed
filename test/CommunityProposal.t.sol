// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {MultiSendCallOnly} from "safe-contracts/libraries/MultiSendCallOnly.sol";

import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

import {IXERC20} from "./interfaces/IXERC20.sol";

import {ForgeHelper} from "./utils/ForgeHelper.sol";
import {ForkHelper} from "./utils/ForkHelper.sol";
import {AddressLookup} from "./utils/AddressLookup.sol";
import {ChainLookup} from "./utils/ChainLookup.sol";

import "forge-std/StdJson.sol";
import "forge-std/console.sol";

// Addresses ----

// 0xFE67A4450907459c3e1FFf623aA927dD4e28c67a - mainnet NEXT token (token1 on mainnet vault)

// 0x58b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e8 - Polygon NEXT token (token0 on arb vault)

// --------

contract CommunityProposal is ForgeHelper {
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

    // Fork management utilities
    ForkHelper public FORK_HELPER;

    // Transactions path
    string public TRANSACTIONS_PATH = "/community-transactions.json";

    // Number of transactions to execute in multisend data:
    // 1. mainnet approval of NEXT to lockbox
    // 2. mainnet deposit on lockbox
    // 3. mainnet approval of xNEXT to connext
    // 4. xcall xNEXT into connext

    uint256 public NUMBER_TRANSACTIONS = 4;

    // Amount to bridge into POL multisig
    uint256 public LIQUIDITY_AMOUNT_POLYGON = 1200000 ether; // used in transactions

    // ================== Setup ==================

    function setUp() public {
        // Create the fork helper for mainnet and polygon
        uint256[] memory chains = new uint256[](2);
        chains[0] = 1;
        chains[1] = 137;

        uint256[] memory blocks = new uint256[](2);

        FORK_HELPER = new ForkHelper(chains, blocks);
        vm.makePersistent(address(FORK_HELPER));

        // Create the forks
        FORK_HELPER.utils_createForks();
        assertEq(FORK_HELPER.utils_getNetworksCount(), 2, "!forks");
    }

    function utils_generateTransactions()
        public
        view
        returns (Transaction[] memory _transactions)
    {
        // Generate executable from `Velodrome-transactions.json`
        string memory path = string.concat(vm.projectRoot(), TRANSACTIONS_PATH);

        string memory json = vm.readFile(path);

        // Generate the bytes of the multisend transactions
        _transactions = new Transaction[](NUMBER_TRANSACTIONS);
        for (uint256 i; i < NUMBER_TRANSACTIONS; i++) {
            string memory baseJsonPath = string.concat(
                ".transactions[",
                i.toString(),
                "]"
            );
            address to = json.readAddress(string.concat(baseJsonPath, ".to"));
            uint256 value = json.readUint(
                string.concat(baseJsonPath, ".value")
            );
            // No way to check if data is null in json, this will revert if data is null
            // TODO: add support to automatically generate data if its null
            bytes memory data = json.readBytes(
                string.concat(baseJsonPath, ".data")
            );

            // Add to transactions
            _transactions[i] = Transaction({
                to: to,
                value: value,
                data: data,
                operation: Operation.Call
            });
        }
    }

    function utils_getXCallTo(
        uint256 transactionIdx
    ) public view returns (address _to) {
        // Generate executable from `Velodrome-transactions.json`
        string memory path = string.concat(vm.projectRoot(), TRANSACTIONS_PATH);

        string memory json = vm.readFile(path);
        string memory jsonPath = string.concat(
            ".transactions[",
            transactionIdx.toString(),
            "].contractInputsValues._to"
        );
        _to = json.readAddress(jsonPath);
    }

    // ================== Tests ==================
    function test_executableShouldPass() public {
        // Generate the multisend transactions
        // bytes memory transactions = utils_generateMultisendTransactions();
        Transaction[] memory transactions = utils_generateTransactions();

        // Select and prep mainnet fork
        vm.selectFork(FORK_HELPER.forkIdsByChain(1));
        address caller = AddressLookup.getConnextDao(1);
        uint256 initial = IERC20(AddressLookup.getNEXTAddress(1)).balanceOf(
            caller
        );
        vm.makePersistent(caller);

        // Submit the transactions
        // NOTE: This assumes signatures will be valid, and the batching of these transactions
        // will be valid. Simply pranks and calls each function in a loop as DAO.
        for (uint256 i; i < transactions.length; i++) {
            // Send tx
            vm.prank(caller);
            (bool success, ) = transactions[i].to.call(transactions[i].data);
            assertTrue(success, string.concat("!success @ ", i.toString()));
        }

        // Select and prep Polygon fork
        vm.selectFork(FORK_HELPER.forkIdsByChain(137));
        caller = AddressLookup.getConnext(137);
        vm.makePersistent(caller);

        // Process polygon xcall for `approval` by transferring to `to`
        address to = utils_getXCallTo(3);
        address asset = AddressLookup.getNEXTAddress(137);
        vm.startPrank(caller);
        uint256 initialbalance = IERC20(AddressLookup.getNEXTAddress(137))
            .balanceOf(to);

        // Mint on NEXT to caller
        IXERC20(asset).mint(to, LIQUIDITY_AMOUNT_POLYGON);
        // No calldata on the xcall
        vm.stopPrank();

        // Ensure the polygon balance increased
        uint256 balance = IERC20(AddressLookup.getNEXTAddress(137)).balanceOf(
            to
        );
        assertEq(
            balance,
            LIQUIDITY_AMOUNT_POLYGON + initialbalance,
            "!balance"
        );

        // Ensure the connext mainnet balance decreased
        vm.selectFork(FORK_HELPER.forkIdsByChain(1));
        assertEq(
            IERC20(AddressLookup.getNEXTAddress(1)).balanceOf(
                AddressLookup.getConnextDao(1)
            ),
            initial - LIQUIDITY_AMOUNT_POLYGON,
            "!balance"
        );
    }
}
