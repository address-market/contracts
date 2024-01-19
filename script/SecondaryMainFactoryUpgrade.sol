// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { SecondaryMainFactory } from "../src/SecondaryMainFactory.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SecondaryMainFactoryUpgrade is Script {
  function run() external {
    vm.startBroadcast();
    ProxyAdmin proxyAdmin = ProxyAdmin(0x560Fe836930d2Be1994c04162089b32791465dB6);
    // ProxyAdmin proxyAdmin = ProxyAdmin(0x7D676152A17c8eaa83e63035158bc71e3893b7C4);
    SecondaryMainFactory mainFactoryImplementation = new SecondaryMainFactory();

    proxyAdmin.upgradeAndCall(
      ITransparentUpgradeableProxy(0x1060235F4C34C1AfEF1d268c532FDb6468d18E06), // proxy
      // ITransparentUpgradeableProxy(0xdfADA12fBEe1e558134a43558728cB8e944650Dd), // proxy
      address(mainFactoryImplementation),
      abi.encodeWithSelector(SecondaryMainFactory.modify.selector)
    );

    vm.stopBroadcast();
  }
}