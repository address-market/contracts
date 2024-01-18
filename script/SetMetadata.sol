// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SetMetadata is Script {
  function run() external {
    vm.startBroadcast();
    MainFactory mainFactory = MainFactory(0xBB884d4EaB637520Ea4e1976D1418EFCAe90D67D);
    mainFactory.setMetaUri('https://meta.address-market.com/bound/');
    vm.stopBroadcast();
  }
}