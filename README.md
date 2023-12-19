# dao-testbed

Foundry-based testing utilities for creating and validating executable crosschain proposals.

## Usage

This repository is designed to help generate and validate executable proposals for the Connext DAO.

### Testing a Proposal

To initiate the proposal testing process, we begin by creating a `transactions.json` file, which encompasses all necessary transaction details.

Our initial step involves determining the method to generate transactions.json files, which are essential for testing executable proposals.

> **NOTE:** In the context of cross-governance (xGov) mechanisms, Connext utilizes xcalls to facilitate the transfer of data and assets across chains. Therefore, the steps for creating a proposal will prominently include the use of xcalls.


### **_Generate your Executable._**
To facilitate a transaction transferring NEXT from Ethereum to Optimism, use the SAFE Transaction Builder application and follow these steps:

    Lockbox Address Approval: Enter and approve the specific Lockbox address.
    Deposit Method: Use the Deposit method on the lockbox to obtain xNEXT tokens.
    Approval for Connext Contracts: Approve the use of xNEXT tokens with Connext contracts.
    Connext Contract xCall: Implement the xcall method on Connext contracts for the transfer process.

For each step, it is crucial to input the appropriate contract address and select the correct methods in the transaction builder. All four transactions should be compiled into a single batch processing.
    
> Note: For reference, a screenshot is attached showing what the first step should look like in the application.
![Screenshot 2023-12-19 at 7 03 38 PM](https://github.com/connext/dao-testbed/assets/56167998/2e4385ea-8a08-498a-b2a4-698df7b93fcc)

Before submitting the payload, download the generated batch and save it under `transactions.json` in this repository.

![Screenshot 2023-12-19 at 7 14 32 PM](https://github.com/connext/dao-testbed/assets/56167998/d0a3a0c6-3b85-40fb-b1ea-1041b14c4385)


> **NOTE:**
If you are generating a complex transaction with ABIs, you will have to submit one `xcall` per `transactions` entry. Further, the downloaded transactions will have `null` data fields in the `transactions` array.

To populate these for each transaction, use `cast calldata`:

```sh
# Sample tx:
############
{
      "to": "0xFE67A4450907459c3e1FFf623aA927dD4e28c67a",
      "value": "0",
      "data": null,
      "contractMethod": {
        "inputs": [
          { "name": "spender", "type": "address", "internalType": "address" },
          { "name": "amount", "type": "uint256", "internalType": "uint256" }
        ],
        "name": "approve",
        "payable": false
      },
      "contractInputsValues": {
        "spender": "0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b",
        "amount": "1500000000000000000000000"
      }
}
###########
cast calldata "approve(address,uint256)" "0xB041f628e961598af9874BCf30CC865f67fad3EE" "10000000000000000000000"

0x095ea7b3000000000000000000000000b041f628e961598af9874bcf30cc865f67fad3ee00000000000000000000000000000000000000000000021e19e0c9bab2400000
```

You should enter the encoded data into the `data` field for each transaction. This step is essential for every transaction you process, ensuring the data field is accurately filled with the necessary encoded information. Once added, the encoded data in the data field for each transaction will resemble the example provided below.

```sh
# Final tx:
{
      "to": "0xFE67A4450907459c3e1FFf623aA927dD4e28c67a",
      "value": "0",
      "data": "0x095ea7b300000000000000000000000022f424bca11fe154c403c277b5f8dab54a4ba29b000000000000000000000000000000000000000000013da329b6336471800000",
      "contractMethod": {
        "inputs": [
          { "name": "spender", "type": "address", "internalType": "address" },
          { "name": "amount", "type": "uint256", "internalType": "uint256" }
        ],
        "name": "approve",
        "payable": false
      },
      "contractInputsValues": {
        "spender": "0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b",
        "amount": "1500000000000000000000000"
      }
}

```

This will give you the `calldata` to use for an `xcall` and other txs. The `to` of the `xcall`s should be the Connext Module on the destination DAO. You can find the addresses for connext daimond in [Connext docs](https://docs.connext.network/resources/deployments).

> **NOTE:** Input struct values as string arrays (i.e. `tuple(address,uint256,uint256) = ["0xe04ccC9004386A5f6fED6804a4d672AFe1f4Ee29","10000000000000000000000","0"]`) when using the SAFE transaction builder.

### **_Writing tests:_**


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

### **_Running the test:_**

- Ensure that Foundry is installed in your system. 
- Create a `.env` file in the root of the repository and copy the content of `.env.example` in it. Make sure to add RPCs of the networks you are going cross-chain 

    ```
    MAINNET_RPC_URL=
    OPTIMISM_RPC_URL=
    BNB_RPC_URL=
    GNOSIS_RPC_URL=
    POLYGON_RPC_URL=
    ARBITRUM_ONE_RPC_URL=
    ```
- build your test contracts using the below command:
    ```sh
        forge init && forge build
    ```

- Run `forge test` to run all the tests. In case you only need one test to run. Use `--match-contract` flag. Ex. below for VelodromeProposal:

    ```sh
    forge test --match-contract VelodromeProposal
    ```


### Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
