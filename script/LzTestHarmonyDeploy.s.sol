// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {LzTest} from "../src/LzTest.sol";
import { console2 } from "forge-std/console2.sol";


contract LzTestHarmonyDeploy is Script {
  function run() external {
    vm.startBroadcast();
    LzTest lz = LzTest(payable(0x0B979585Dcb0BF55cA62548daF4180E7bF7bB83d));
    console2.logAddress(lz.owner());
    lz.setTrustedRemoteAddress(109, abi.encodePacked(0x1333bB4A40D41F43A38A1F62F08C0EB7d272D82c));
    vm.stopBroadcast();
  }
}
