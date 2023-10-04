// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPALMTerms {
    struct IncreaseBalance {
        address vault;
        uint256 amount0;
        uint256 amount1;
    }

    // #region events.

    event AddVault(address creator, address vault);
    event DelegateVault(address creator, address vault, address delegate);

    event SetupVault(address creator, address vault);
    event IncreaseLiquidity(address creator, address vault);

    function increaseLiquidity(IncreaseBalance calldata increaseBalance_)
        external;
}
