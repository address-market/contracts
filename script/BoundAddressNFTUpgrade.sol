// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {BoundAddressNFT} from "../src/BoundAddressNFT.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BoundAddressNFTUpgrade is Script {
  function run() external {
    vm.startBroadcast();
    ProxyAdmin proxyAdmin = ProxyAdmin(0x7D676152A17c8eaa83e63035158bc71e3893b7C4);
    BoundAddressNFT implementation = new BoundAddressNFT();

    proxyAdmin.upgrade(
      ITransparentUpgradeableProxy(0xBB884d4EaB637520Ea4e1976D1418EFCAe90D67D), // proxy
      address(implementation)
    );

    vm.stopBroadcast();
  }
}