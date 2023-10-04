// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IXERC20 is IERC20Metadata {
    function mint(address account, uint256 value) external;
    function burn(address account, uint256 value) external;
}