// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChainLookup {
  function getRpcEnvName(uint256 _chainId) public pure returns (string memory) {
    // Mainnets
    if (_chainId == 1) {
      return "MAINNET_RPC_URL";
    }

    if (_chainId == 10) {
      return "OPTIMISM_RPC_URL";
    }

    if (_chainId == 56) {
      return "BNB_RPC_URL";
    }

    if (_chainId == 100) {
      return "GNOSIS_RPC_URL";
    }

    if (_chainId == 137) {
      return "POLYGON_RPC_URL";
    }

    if (_chainId == 42161) {
      return "ARBITRUM_ONE_RPC_URL";
    }

    // Testnets
    if (_chainId == 5) {
      return "GOERLI_RPC_URL";
    }

    if (_chainId == 420) {
      return "OPTIMISM_GOERLI_RPC_URL";
    }

    if (_chainId == 80001) {
      return "MUMBAI_RPC_URL";
    }

    if (_chainId == 421613) {
      return "ARBITRUM_GOERLI_RPC_URL";
    }

    require(false, "!rpc env var for chain");
  }

  function getDomainId(uint256 _chainId) public pure returns (uint32) {
    // Mainnets
    if (_chainId == 1) {
      return 6648936;
    }

    if (_chainId == 10) {
      return 1869640809;
    }

    if (_chainId == 56) {
      return 6450786;
    }

    if (_chainId == 100) {
      return 6778479;
    }

    if (_chainId == 137) {
      return 1886350457;
    }

    if (_chainId == 42161) {
      return 1634886255;
    }

    // Testnets -- TODO

    require(false, "!domain for chain");
  }

  function getNetworkName(uint256 _chainId) public pure returns (string memory) {
    // Mainnets
    if (_chainId == 1) {
      return "mainnet";
    }

    if (_chainId == 10) {
      return "optimism";
    }

    if (_chainId == 56) {
      return "bnb";
    }

    if (_chainId == 100) {
      return "xdai";
    }

    if (_chainId == 137) {
      return "matic";
    }

    if (_chainId == 42161) {
      return "arbitrum-one";
    }

    // Testnets
    if (_chainId == 5) {
      return "goerli";
    }

    if (_chainId == 420) {
      return "optimism-goerli";
    }

    if (_chainId == 80001) {
      return "mumbai";
    }

    if (_chainId == 421613) {
      return "arbitrum-goerli";
    }

    require(false, "!network name for chain");
  }

  function getMainnetChainIds() public pure returns (uint256[] memory _mainnets) {
    _mainnets = new uint256[](6);
    _mainnets[0] = 1;
    _mainnets[1] = 10;
    _mainnets[2] = 56;
    _mainnets[3] = 100;
    _mainnets[4] = 137;
    _mainnets[5] = 42161;
  }

  function getTestnetChainIds() public pure returns (uint256[] memory _mainnets) {
    _mainnets = new uint256[](4);
    _mainnets[0] = 5;
    _mainnets[1] = 420;
    _mainnets[2] = 80001;
    _mainnets[3] = 421613;
  }
}
