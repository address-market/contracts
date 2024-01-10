// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MainFactoryUpgrade is Script {
  function run() external {
    vm.startBroadcast();
    ProxyAdmin proxyAdmin = ProxyAdmin(0xEBfC0594aF64b446199a8512Fa396948FD8C583A);
    MainFactory mainFactoryImplementation = new MainFactory();

    proxyAdmin.upgradeAndCall(
      ITransparentUpgradeableProxy(0x551518ceA0b6f972fE6707B4c233d3E5db2c990b), // proxy
      address(mainFactoryImplementation),
      abi.encodeWithSelector(MainFactory.modify.selector)
    );

    vm.stopBroadcast();
  }
}