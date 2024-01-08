// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MainFactory.sol";
import "../src/IntermediateFactory.sol";
import "../src/Constants.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";


contract MainFactoryTest is Test, Constants {
  MainFactory public mainFactory;

  address constant _OWNER = 0x90Ad080DBfd9cB333bA200025f3a2666071555D9;

  function setUp() public {
    vm.startPrank(_OWNER);
    vm.deal(_OWNER, 100 ether);
    console.log("owner: %s", _OWNER);

    // 1) deploy ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    // 2) deploy IF
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

    mainFactory = MainFactory(address(MFProxy));
  }

  function testMintNft() external {
    uint256 randomFactor = 123;
    bytes32 salt = bytes32(uint256(111));

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
    console.log('precomp addr', _precompute(0xfBA25AcF53b559eA4feB3ed69F357189FCc4F421, bytes32(uint256(6167569445235488))));

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
    mainFactory.deploy(tokenId, sampleCode);


    // TODO used hash
  }
}
