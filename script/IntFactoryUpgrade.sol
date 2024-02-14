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

    MainFactory mainFactory = MainFactory(0xB9af59262147673C2016b2b10808411166756ed3);


    mainFactory.setIntermediateFactory(implementation);

    vm.stopBroadcast();
  }
}