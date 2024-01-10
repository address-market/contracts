// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721EnumerableUpgradeable, ERC721Upgradeable} from "openzeppelin/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {Constants} from "./Constants.sol";
import {IntermediateFactory} from "./IntermediateFactory.sol";
import {DustNFT} from "./DustNFT.sol";
import {OwnableUpgradeable} from "openzeppelin/access/OwnableUpgradeable.sol";

contract MainFactory is
  ERC721EnumerableUpgradeable,
  Constants,
  OwnableUpgradeable
{
  event SetIntermediateFactory(IntermediateFactory intermediateFactory);
  event SetDustNft(DustNFT dustNft);

  IntermediateFactory public intermediateFactory;

  string public metaUri;

  mapping(bytes32 => bool) private hashUsed;
  mapping(bytes32 => address) private whoCommited;
  mapping(uint256 => bytes32) public tokenIdToSalt;
  uint256 reservedForPermanentLock;
  // mapping(uint256 => bool) public permanentLock;

  uint256 reservedForDeployPrices;
  // mapping(uint256 => uint256) public deployPrices;

  DustNFT public dustNft;

  uint256[50] _____gap;

  event Modified();

  function modify() external { // 0x64cf33b8
    // code for modifying while upgrading
    emit Modified();
  }

  function initialize(
    IntermediateFactory _intermediateFactory
  ) external initializer {
    __ERC721_init("Address Market", "ADD");
    __ERC721Enumerable_init();
    __Ownable_init();

    intermediateFactory = _intermediateFactory;
    emit SetIntermediateFactory(_intermediateFactory);
  }

  function setMetaUri(string calldata _metaUri) external onlyOwner {
    metaUri = _metaUri;
  }

  function commit(bytes32 _hash) external {
    if (hashUsed[_hash] != false) revert UsedHash();
    if (whoCommited[_hash] != address(0)) revert CommittedHash();
    whoCommited[_hash] = msg.sender;
    emit Commit(msg.sender, _hash);
  }

  function reveal(bytes32 salt, uint256 randomFactor) external returns (uint256 tokenId) {
    bytes32 _hash = keccak256(abi.encodePacked(salt, randomFactor));
    address addressPrecomputed = _precompute(address(this), salt);
    tokenId = uint256(uint160(addressPrecomputed));

    if (whoCommited[_hash] != msg.sender) {
      revert HashNotFound();
    }
    if (hashUsed[_hash]) {
      revert HashAlreadyUsed();
    }
    if (tokenIdToSalt[tokenId] != 0) {
      revert AddressWasDeployed();
    }
    hashUsed[_hash] = true;
    whoCommited[_hash] = address(0);
    _mint(msg.sender, tokenId);
    tokenIdToSalt[tokenId] = salt;
    emit Mint(msg.sender, tokenId, salt, addressPrecomputed);
  }

  // deploys ./yul/UpgradeableClone.yul
  // 0x6034600d60003960346000f3fe6000548060008114602b573660008037600080366000855af43d6000803e806026573d6000fd5b3d6000f35b6000356000555050
  function UpgradeableCloneDeterministic(bytes32 salt) internal returns (address instance) {
    assembly {
      let position := mload(0x40)
      mstore(position, 0x60)
      mstore(add(position, 0x20), 0x34600d60003960346000f3fe6000548060008114602b57366000803760008036)
      mstore(add(position, 0x40), 0x6000855af43d6000803e806026573d6000fd5b3d6000f35b6000356000555050)
      instance := create2(0, add(position, 0x1f), 65, salt)
    }
    require(instance != address(0), "Create2 failed");
  }

  function _deploy(bytes32 salt, bytes memory code) internal returns (address) {
    address cloneAddress = UpgradeableCloneDeterministic(salt);
    (bool success, ) = cloneAddress.call(abi.encode(intermediateFactory));
    require(success); // TODO
    IntermediateFactory intermediateFactoryClone = IntermediateFactory(cloneAddress);

    return intermediateFactoryClone.deploy(code); // deploy from factory using create opcode (not create2)
  }

  function deploy(uint256 tokenId, bytes memory code) external returns (address deployedAddress) {
    if (ownerOf(tokenId) != msg.sender) {
      revert WrongOwner();
    }
    bytes32 salt = tokenIdToSalt[tokenId];
    deployedAddress = _deploy(salt, code);
    _burn(tokenId);
    dustNft.mint(msg.sender, tokenId);
  }

  // override ERC721 methods
  function _baseURI() internal view override returns (string memory) {
    return metaUri;
  }

  function setIntermediateFactory(IntermediateFactory _intermediateFactory) external onlyOwner {
    intermediateFactory = _intermediateFactory;
    emit SetIntermediateFactory(_intermediateFactory);
  }

  function setDustNft(DustNFT _dustNft) external onlyOwner {
    dustNft = _dustNft;
    emit SetDustNft(_dustNft);
  }
}
