// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MainFactory.sol";
import "../src/BoundAddressNFT.sol";
import "../src/IntermediateFactory.sol";
import "../src/Constants.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";


contract MainFactoryTest is Test, Constants {
  MainFactory public mainFactory;
  BoundAddressNFT public boundAddressNFT;

  address constant _OWNER = 0xD051a9EA4A68B0143d49bAbf226BdAeba316bF05;

  function setUp() public {
    vm.startPrank(_OWNER);
    vm.deal(_OWNER, 100 ether);

    // deploy process should match AddressMarket.deploy.sol

    // 1) deploy ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin();

    // 2) deploy IF
    IntermediateFactory intermediateFactory = new IntermediateFactory();
    
    // 3) deploy MF-Implementation
    MainFactory mainFactoryImplementation = new MainFactory();

    // 4) set up MF-Proxy
    TransparentUpgradeableProxy MFProxy = new TransparentUpgradeableProxy(
      address(mainFactoryImplementation),
      address(proxyAdmin),
      abi.encodeWithSelector(MainFactory.initialize.selector, address(intermediateFactory))
    );

    // 5) deploy BoundAddressNFT
    BoundAddressNFT boundAddressNftLogic = new BoundAddressNFT();
    TransparentUpgradeableProxy boundAddressNftProxy = new TransparentUpgradeableProxy(
      address(boundAddressNftLogic),
      address(proxyAdmin),
      abi.encodeWithSelector(BoundAddressNFT.initialize.selector, address(MFProxy))
    );
    MainFactory(address(MFProxy)).setBoundAddressNFT(BoundAddressNFT(address(boundAddressNftProxy)));

    mainFactory = MainFactory(address(MFProxy));
    boundAddressNFT = BoundAddressNFT(address(boundAddressNftProxy));
  }

  function testMintNft() external {
    uint256 randomFactor = 123;
    bytes32 salt = bytes32(uint256(131035919034));

    // predict address for the salt
    address precomputed = _precompute(address(mainFactory), salt);
    uint256 tokenId = uint256(uint160(precomputed));

    bytes32 _hash = keccak256(abi.encodePacked(salt, randomFactor));
    vm.expectEmit(true, false, false, true);
    emit Commit(_OWNER, _hash);
    mainFactory.commit(_hash);

    vm.expectEmit(true, false, false, true);
    emit Mint(_OWNER, tokenId, salt, precomputed);
    mainFactory.reveal(salt, randomFactor);

    bytes memory testCode = abi.encodePacked(uint88(0x600180600b6000396000f3));
    mainFactory.deploy(tokenId, testCode);
  }

  function testCommitRevealMint() public {
    uint256 randomFactor = 12345;
    bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked("salt"))));
    bytes32 wrongSalt = bytes32(uint256(keccak256(abi.encodePacked("wrongSalt"))));
    bytes32 _hash = keccak256(abi.encodePacked(salt, randomFactor));
    vm.expectEmit(true, false, false, true);
    emit Commit(_OWNER, _hash);
    mainFactory.commit(_hash);
    vm.expectRevert(CommittedHash.selector);
    mainFactory.commit(_hash);

    vm.expectRevert(HashNotFound.selector);
    mainFactory.reveal(wrongSalt, randomFactor);

    address precomputed = _precompute(address(mainFactory), salt);
    uint256 tokenId = uint256(uint160(precomputed));

    vm.expectEmit(true, false, false, true);
    emit Mint(_OWNER, tokenId, salt, precomputed);
    mainFactory.reveal(salt, randomFactor);

    bytes memory sampleCode = type(IntermediateFactory).creationCode;
    address deployed = mainFactory.deploy(tokenId, sampleCode);

    assertEq(deployed, precomputed, "deployed address should be precomputed");

    // TODO used hash
  }
}
