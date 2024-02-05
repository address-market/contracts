// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { IntermediateFactory } from "../src/IntermediateFactory.sol";
import { BoundAddressNFT } from "../src/BoundAddressNFT.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { console } from "forge-std/console.sol";

/**
 * Deploy to anvil:
 * forge script AddressMarketDeploy --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvv
 * IF Proxy: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
 * MF Proxy: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
 *
 * 1) deploy this and input endpoint lz address BEFORE
 */
contract AddressMarketDeploy is Script {
  function run() external {
    vm.startBroadcast();

    // 1) deploy ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin();

    // 2) deploy IF
    IntermediateFactory intermediateFactory = new IntermediateFactory();
    
    // 3) deploy MF-Implementation
    MainFactory mainFactoryImplementation = new MainFactory();

    // 4) deploy MF-Proxy
    TransparentUpgradeableProxy MFProxy = new TransparentUpgradeableProxy(
      address(mainFactoryImplementation),
      address(proxyAdmin),
      abi.encodeWithSelector(MainFactory.initialize.selector, address(intermediateFactory))
    );

    // 5) deploy BoundAddressNFT
    BoundAddressNFT boundAddressNftLogic = new BoundAddressNFT();
    // 6
    TransparentUpgradeableProxy boundAddressNftProxy = new TransparentUpgradeableProxy(
      address(boundAddressNftLogic),
      address(proxyAdmin),
      abi.encodeWithSelector(BoundAddressNFT.initialize.selector, address(MFProxy))
    );
    MainFactory(address(MFProxy)).setBoundAddressNFT(BoundAddressNFT(address(boundAddressNftProxy)));
    MainFactory(address(MFProxy)).setMetaUri("https://meta.address-market.com/");
    BoundAddressNFT(address(boundAddressNftProxy)).setMetaUri("https://meta.address-market.com/bound/");
    MainFactory(address(MFProxy)).toggleChainToMint(116, true);
    MainFactory(address(MFProxy)).toggleChainToMint(145, true);

    vm.stopBroadcast();
  }
}