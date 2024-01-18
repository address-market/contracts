// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/BoundAddressNFT.sol";


contract BoundAddressBugTest is Test {
  BoundAddressNFT public boundAddressNFT;

  function setUp() external {

  }

  function test_Bug() external {
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    BoundAddressNFT boundAddressNftLogic = new BoundAddressNFT();
    TransparentUpgradeableProxy boundAddressNftProxy = new TransparentUpgradeableProxy(
      address(boundAddressNftLogic),
      address(proxyAdmin),
      abi.encodeWithSelector(BoundAddressNFT.initialize.selector, address(this))
    );
    boundAddressNFT = BoundAddressNFT(address(boundAddressNftProxy));

    // boundAddressNFT.initialize(address(this));
    boundAddressNFT.mint(address(333), 1, true);
    uint256 addressBalance = boundAddressNFT.balanceOf(address(333));
    console.log(addressBalance);
    uint256 tokenId = boundAddressNFT.tokenOfOwnerByIndex(address(333), 0);
    console.log(tokenId);
  }
}
