// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";


contract IntermediateFactory {
  function deploy(bytes memory code) external returns (address addr) {
    assembly {
      addr := create(0, add(code, 0x20), mload(code))
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
  }
}
