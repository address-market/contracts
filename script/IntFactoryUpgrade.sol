// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IntermediateFactory } from "../src/IntermediateFactory.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract IntFactoryUpgrade is Script {
  function run() external {
    vm.startBroadcast();
    IntermediateFactory implementation = new IntermediateFactory();

    MainFactory mainFactory = MainFactory(0xdfADA12fBEe1e558134a43558728cB8e944650Dd);


    mainFactory.setIntermediateFactory(implementation);

    vm.stopBroadcast();
  }
}