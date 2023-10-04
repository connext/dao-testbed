// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressLookup {
  function getConnext(uint256 _chainId) public pure returns (address) {
    // Mainnets
    if (_chainId == 1) {
      return address(0x8898B472C54c31894e3B9bb83cEA802a5d0e63C6);
    }

    if (_chainId == 10) {
      return address(0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA);
    }

    if (_chainId == 56) {
      return address(0xCd401c10afa37d641d2F594852DA94C700e4F2CE);
    }

    if (_chainId == 100) {
      return address(0x5bB83e95f63217CDa6aE3D181BA580Ef377D2109);
    }

    if (_chainId == 137) {
      return address(0x11984dc4465481512eb5b777E44061C158CF2259);
    }

    if (_chainId == 42161) {
      return address(0xEE9deC2712cCE65174B561151701Bf54b99C24C8);
    }

    // Testnets
    if (_chainId == 5) {
      return address(0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649);
    }

    if (_chainId == 420) {
      return address(0x5Ea1bb242326044699C3d81341c5f535d5Af1504);
    }

    if (_chainId == 80001) {
      return address(0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a);
    }

    if (_chainId == 421613) {
      return address(0x2075c9E31f973bb53CAE5BAC36a8eeB4B082ADC2);
    }

    require(false, "!connext for chain");
  }

  function getNEXTAddress(uint256 _chainId) public pure returns (address) {
    // Mainnets
    if (_chainId == 1) {
      return address(0xFE67A4450907459c3e1FFf623aA927dD4e28c67a);
    }

    if (_chainId == 10 || _chainId == 56 || _chainId == 100 ||_chainId == 137 ||_chainId == 42161) {
      return address(0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8);
    }

    require(false, "!connext for chain");
  }

  function getConnextDao(uint256 _chainId) public pure returns (address) {
    // Mainnets
    if (_chainId == 1) {
      return address(0x4d50a469fc788a3c0CdC8Fd67868877dCb246625);
    }

    if (_chainId == 10) {
      return address(0x6eCeD04DdC5A7709d5877c963cED0288Fb1c7348);
    }

    if (_chainId == 56) {
      return address(0x9435Ba7C661a0Fd477deED640491de8c100325A7);
    }

    if (_chainId == 100) {
      return address(0x7616Bc6d0dee5E250BA5b3dDa6cbbB71786FB638);
    }

    if (_chainId == 137) {
      return address(0x0970Adeb473609F91D03e9Bba85F49C445040cD7);
    }

    if (_chainId == 42161) {
      return address(0x5C711DB90dEc0a5B81C626968DEa4187a7f9C1F2);
    }

    require(false, "!dao for chain");
  }
}
