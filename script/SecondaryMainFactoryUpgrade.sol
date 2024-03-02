// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { SecondaryMainFactory } from "../src/SecondaryMainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SecondaryMainFactoryUpgrade is Script {
  function run() external {
    vm.startBroadcast();
    ProxyAdmin proxyAdmin = ProxyAdmin(0x4C17A20b7445F7Eaae37E50792fff2CCECe8728d);
    // ProxyAdmin proxyAdmin = ProxyAdmin(0x7D676152A17c8eaa83e63035158bc71e3893b7C4);
    SecondaryMainFactory mainFactoryImplementation = new SecondaryMainFactory();

    proxyAdmin.upgradeAndCall(
      ITransparentUpgradeableProxy(0xB9af59262147673C2016b2b10808411166756ed3), // proxy
      address(mainFactoryImplementation),
      abi.encodeWithSelector(SecondaryMainFactory.modify.selector)
    );

    vm.stopBroadcast();
  }
}