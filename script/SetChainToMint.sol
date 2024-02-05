// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


// only for polygon

contract SetChainToMint is Script {
  function run() external {
    vm.startBroadcast();
    MainFactory mainFactory = MainFactory(0xB9af59262147673C2016b2b10808411166756ed3);
    mainFactory.toggleChainToMint(101, true);
    vm.stopBroadcast();
  }
}