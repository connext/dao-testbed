# dao-testbed

# <h1 align="center"> dao-testbed </h1>

Foundry-based testing utilities for creating and validating executable crosschain proposals.

## Usage

This repository is designed to help generate and validate executable proposals for the Connext DAO.

### Testing a Proposal

_1. Fork this repository._
Create a fork of this repo, and create your test file using [`TODO`](TODO) as a template.

_2. Generate your Executable._
You can generate same-chain executables using the SAFE transaction builder application. Before submitting the payload, download the generated batch and save it under `transactions.json` in this repository.

Generate cross-chain executables using the [crosschain SAFE transaction builder](TODO). First, you have to generate the `data` to input into the widget. To generate this data, you can use the SAFE transaction builder application on the chain you intend to execute the transaction on and download the generated batch prior to submission. Extract the `TODO` data from the file, and input that into the `data` field in the widget.

**NOTE:**
If you are generating a complex transaction with ABIs, you will have to submit one `xcall` per `transactions` entry. Further, the downloaded transactions will have `null` data fields in the `transactions` array.

To populate these for each transaction, use `cast calldata`:

```sh
# Sample tx:
# {
#     "to": "0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8",
#     "value": "0",
#     "data": null,
#     "contractMethod": {
#         "inputs": [
#             {
#                 "internalType": "address",
#                 "name": "spender",
#                 "type": "address"
#             },
#             {
#                 "internalType": "uint256",
#                 "name": "amount",
#                 "type": "uint256"
#             }
#         ],
#         "name": "approve",
#         "payable": false
#     },
#     "contractInputsValues": {
#         "admin": "",
#         "spender": "0xB041f628e961598af9874BCf30CC865f67fad3EE",
#         "amount": "10000000000000000000000"
#     }
# }
cast calldata "approve(address,uint256)" "0xB041f628e961598af9874BCf30CC865f67fad3EE" "10000000000000000000000"

0x095ea7b3000000000000000000000000b041f628e961598af9874bcf30cc865f67fad3ee00000000000000000000000000000000000000000000021e19e0c9bab2400000
```

To further populate the encoded data to include on the origin chain, run the following with the data output from above as the `bytes` argument:

```sh
cast abi-encode "execAndReturnData(address,uint256,bytes,uint8)" "0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8" "0" "0x095ea7b3000000000000000000000000b041f628e961598af9874bcf30cc865f67fad3ee00000000000000000000000000000000000000000000021e19e0c9bab2400000" "0"

0x00000000000000000000000058b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000b041f628e961598af9874bcf30cc865f67fad3ee00000000000000000000000000000000000000000000021e19e0c9bab240000000000000000000000000000000000000000000000000000000000000
```

This will give you the `calldata` to use for an `xcall`. The `to` of the `xcall`s should be the Connext Module on the destination DAO. The `xcalls` can then be added directly via the SAFE transaction builder on the origin chain.

**NOTE:** Input struct values as string arrays (i.e. `tuple(address,uint256,uint256) = ["0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29","10000000000000000000000","0"]`) when using the SAFE transaction builder.

## Foundry

### Getting Started

Click "Use this template" on [GitHub](https://github.com/foundry-rs/forge-template) to create a new repository with this repo as the initial state.

Or, if your repo already exists, run:

```sh
forge init
forge build
forge test
```

### Writing your first test

All you need is to `import forge-std/Test.sol` and then inherit it from your test contract. Forge-std's Test contract comes with a pre-instatiated [cheatcodes environment](https://book.getfoundry.sh/cheatcodes/), the `vm`. It also has support for [ds-test](https://book.getfoundry.sh/reference/ds-test.html)-style logs and assertions. Finally, it supports Hardhat's [console.log](https://github.com/brockelmore/forge-std/blob/master/src/console.sol). The logging functionalities require `-vvvv`.

```solidity
pragma solidity 0.8.10;

import "forge-std/Test.sol";

contract ContractTest is Test {
    function testExample() public {
        vm.roll(100);
        console.log(1);
        emit log("hi");
        assertTrue(true);
    }
}
```

### Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
