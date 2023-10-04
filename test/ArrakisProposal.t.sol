// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {MultiSendCallOnly} from "safe-contracts/libraries/MultiSendCallOnly.sol";

import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

import {IPALMTerms} from "./interfaces/IPALMTerms.sol";
import {IXERC20} from "./interfaces/IXERC20.sol";

import {ForgeHelper} from "./utils/ForgeHelper.sol";
import {ForkHelper} from "./utils/ForkHelper.sol";
import {AddressLookup} from "./utils/AddressLookup.sol";
import {ChainLookup} from "./utils/ChainLookup.sol";

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
    // 3. mainnet approval of NEXT to lockbox
    // 4. deposit NEXT into lockbox
    // 5. mainnet approval of NEXT to connext
    // 6. an xcall with multicall calldata that will:
    //    - arbitrum approval of NEXT to terms (module approves)
    //    - arbitrum increaseLiquidity on terms (module is caller)
    uint256 public NUMBER_TRANSACTIONS = 6;

    uint256 public LIQUIDITY_AMOUNT = 10000 ether; // used in transactions

    // ================== Setup ==================

    function setUp() public {
        // Create the fork helper for mainnet and arbitrum
        uint256[] memory chains = new uint256[](2);
        chains[0] = 1;
        chains[1] = 42161;
        FORK_HELPER = new ForkHelper(chains);
        vm.makePersistent(address(FORK_HELPER));

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

    function utils_getXCallData(uint256 transactionIdx) public view returns (bytes memory _calldata) {
        // Generate executable from `arrakis-transactions.json`
        string memory path = string.concat(
            vm.projectRoot(),
            TRANSACTIONS_PATH
        );

        string memory json = vm.readFile(path);
        string memory jsonPath = string.concat(".transactions[", transactionIdx.toString(), "].contractInputsValues._callData");
        _calldata = json.readBytes(jsonPath);
    }

    function utils_getXCallTo(uint256 transactionIdx) public view returns (address _to) {
        // Generate executable from `arrakis-transactions.json`
        string memory path = string.concat(
            vm.projectRoot(),
            TRANSACTIONS_PATH
        );

        string memory json = vm.readFile(path);
        string memory jsonPath = string.concat(".transactions[", transactionIdx.toString(), "].contractInputsValues._to");
        _to = json.readAddress(jsonPath);
    }

    function utils_getEncodedXCallData() public view returns (bytes memory _calldata) {
        // Get multisend transactions
        Transaction[] memory transactions = new Transaction[](2);

        // 1. approve NEXT to terms
        transactions[0] = Transaction({
            to: AddressLookup.getNEXTAddress(42161),
            value: 0,
            data: abi.encodeWithSelector(
                IERC20.approve.selector,
                ARRAKIS_PALM_TERMS,
                LIQUIDITY_AMOUNT
            ),
            operation: Operation.Call
        });

        // 2. increaseLiquidity on terms
        transactions[1] = Transaction({
            to: ARRAKIS_PALM_TERMS,
            value: 0,
            data: abi.encodeWithSelector(
                IPALMTerms.increaseLiquidity.selector,
                IPALMTerms.IncreaseBalance(ARRAKIS_ARBITRUM, LIQUIDITY_AMOUNT, 0)
            ),
            operation: Operation.Call
        });

        // encode multisend transactions into expected format
        bytes memory _transactions;
        for (uint256 i; i < transactions.length; i++) {
            _transactions = bytes.concat(
                _transactions,
                abi.encodePacked(
                    transactions[i].operation,
                    transactions[i].to,
                    transactions[i].value,
                    transactions[i].data.length,
                    transactions[i].data
                )
            );
        }

        // Get the multisend transaction to be executed on xcall
        Transaction memory multisend = Transaction({
            to: MULTISEND,
            value: 0,
            data: abi.encodeWithSelector(
                MultiSendCallOnly.multiSend.selector,
                _transactions
            ),
            operation: Operation.DelegateCall
        });

        // return this as the encodePacked calldata
        _calldata = abi.encode(
            multisend.to,
            multisend.value,
            multisend.data,
            multisend.operation
        );
    }

    // ================== Tests ==================
    function test_executableShouldPass() public {
        // Generate the multisend transactions
        // bytes memory transactions = utils_generateMultisendTransactions();
        Transaction[] memory transactions = utils_generateTransactions();

        // Select and prep mainnet fork
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

        // Select and prep arbitrum fork
        vm.selectFork(FORK_HELPER.forkIdsByChain(42161));
        caller = AddressLookup.getConnext(42161);
        vm.makePersistent(caller);

        // NOTE: useful logs for tenderly sims and explorer debugging
        // (address _to, uint256 _value, bytes memory _data, Operation _operation) = abi.decode(
        //     utils_getXCallData(5),
        //     (address, uint256, bytes, Operation)
        // );
        // console.log("generated xcall data");
        // console.log("receiver", utils_getXCallTo(5));
        // console.log("to", _to);
        // console.log("value", _value);
        // console.log("operation", uint256(_operation));
        // console.log("data");
        // console.logBytes(_data);

        // console.log("calldata");
        // console.logBytes(
        //     abi.encodeWithSelector(
        //         IXReceiver.xReceive.selector, 
        //         bytes32("transfer"),
        //         LIQUIDITY_AMOUNT,
        //         AddressLookup.getNEXTAddress(42161),
        //         AddressLookup.getConnextDao(1),
        //         ChainLookup.getDomainId(1),
        //         utils_getXCallData(5)
        //     )
        // );

        // Process arbitrum xcall for `approval` by transferring to `to`
        // and calling xreceive
        address to = utils_getXCallTo(5);
        address asset = AddressLookup.getNEXTAddress(42161);
        vm.startPrank(caller);
        // Mint on NEXT to caller
        IXERC20(asset).mint(to, LIQUIDITY_AMOUNT);
        // Call xreceive
        IXReceiver(to).xReceive(
            bytes32("transfer"),
            LIQUIDITY_AMOUNT,
            asset,
            AddressLookup.getConnextDao(1),
            ChainLookup.getDomainId(1),
            utils_getXCallData(5)
        );
        vm.stopPrank();

        // Assert final balance of mainnet and arbitrum vaults
        for (uint256 i; i < FORK_HELPER.utils_getNetworksCount(); i++) {
            uint256 chainId = FORK_HELPER.NETWORK_IDS(i);
            address vault = chainId == 1 ? ARRAKIS_MAINNET : ARRAKIS_ARBITRUM;
            vm.selectFork(FORK_HELPER.forkIdsByChain(chainId));
            uint256 balance = IERC20(AddressLookup.getNEXTAddress(chainId)).balanceOf(vault);
            assertEq(balance, LIQUIDITY_AMOUNT, "!balance");
        }
    }

    function test_logXCallData() public {
        bytes memory _calldata = utils_getEncodedXCallData();
        (address _to, uint256 _value, bytes memory _data, Operation _operation) = abi.decode(
            _calldata,
            (address, uint256, bytes, Operation)
        );
        assertEq(_to, MULTISEND, "!to");
        assertEq(_value, 0, "!value");
        assertEq(uint256(_operation), 1, "!operation");
        assertTrue(_data.length > 0, "!_data");
        // console.log("calldata");
        // console.logBytes(_calldata);
    }
}