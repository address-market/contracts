// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IntermediateFactory } from "./IntermediateFactory.sol";
import { ECDSAUpgradeable } from "openzeppelin/utils/cryptography/ECDSAUpgradeable.sol";

abstract contract Constants {
  event Commit(address indexed who, bytes32 hash);
  event Mint(address indexed who, uint256 tokenId, bytes32 salt, address addressPrecomputed);
  event DeployPriceSet(uint256 indexed chainId, uint256 price);
  event WantDeploy(uint256 chainId, bytes bytecode);

  error UsedHash();
  error CommittedHash();
  error HashNotFound();
  error RecoverError(ECDSAUpgradeable.RecoverError);
  error WrongSigner();
  error TokenLocked();
  error WrongChainIds();
  error HashAlreadyUsed();
  error AddressWasDeployed();
  error WrongOwner();

  function _precompute(address mainFactory, bytes32 salt) internal pure returns (address) {
    bytes memory creationCode = abi.encodePacked(uint8(0x60), uint256(0x34600d60003960346000f3fe6000548060008114602b57366000803760008036), uint256(0x6000855af43d6000803e806026573d6000fd5b3d6000f35b6000356000555050));
    address factoryAddressPrecomputed = address(uint160(uint256(keccak256(abi.encodePacked(
      bytes1(0xff),
      address(mainFactory),
      salt,
      keccak256(creationCode)
    )))));
    uint8 _nonce = 1; uint8 rlpThing1 = 0xd6; uint8 rlpThing2 = 0x94;
    // S.O.: https://ethereum.stackexchange.com/a/47083/72642
    return address(uint160(uint256(keccak256(abi.encodePacked(rlpThing1, rlpThing2, factoryAddressPrecomputed, _nonce)))));
  }
}
