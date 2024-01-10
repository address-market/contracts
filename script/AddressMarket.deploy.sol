// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MainFactory } from "../src/MainFactory.sol";
import { IntermediateFactory } from "../src/IntermediateFactory.sol";
import { DustNFT } from "../src/DustNFT.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { console } from "forge-std/console.sol";

/**
 * Deploy to anvil:
 * forge script NFTOptionsDeploy --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvv
 * IF Proxy: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
 * MF Proxy: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
 */
contract AddressMarketDeploy is Script {
  function run() external {
    vm.startBroadcast();
    // 1) deploy ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin();

    // 2) deploy IF-Implementation
    IntermediateFactory intermediateFactory = new IntermediateFactory();
    
    // 3) deploy MF-Implementation
    MainFactory mainFactoryImplementation = new MainFactory();

    // 4) deploy MF-Proxy 0xfBA25AcF53b559eA4feB3ed69F357189FCc4F421
    TransparentUpgradeableProxy MFProxy = new TransparentUpgradeableProxy(
      address(mainFactoryImplementation),
      address(proxyAdmin),
      abi.encodeWithSelector(MainFactory.initialize.selector, intermediateFactory)
    );

    // 5) deploy DustNFT
    DustNFT dustNft = new DustNFT(address(MFProxy));
    MainFactory(address(MFProxy)).setDustNft(dustNft);

    vm.stopBroadcast();
  }
}