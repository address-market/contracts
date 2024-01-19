// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {LzTestSend} from "../src/LzTestSend.sol";

contract LzTestPolygonDeploy is Script {
  function run() external {
    vm.startBroadcast();
    // LzTestSend lz = new LzTestSend();
    LzTestSend lz = LzTestSend(payable(0x1333bB4A40D41F43A38A1F62F08C0EB7d272D82c));
    lz.send{ value: 0.5 ether }(address(0x4444), 777);
    vm.stopBroadcast();
  }
}
