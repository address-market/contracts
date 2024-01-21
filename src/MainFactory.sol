// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721EnumerableUpgradeable} from "openzeppelin/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {Constants} from "./Constants.sol";
import {IntermediateFactory} from "./IntermediateFactory.sol";
import {BoundAddressNFT} from "./BoundAddressNFT.sol";
import {OwnableUpgradeable} from "openzeppelin/access/OwnableUpgradeable.sol";


interface ILayerZeroEndpoint {
  function send(
    uint16 _dstChainId,
    bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;
}

contract MainFactory is
  ERC721EnumerableUpgradeable,
  Constants,
  OwnableUpgradeable
{
  error CannotSendToChain();
  error SameBlockReveal();
  event SetIntermediateFactory(IntermediateFactory intermediateFactory);
  event SetBoundAddressNFT(BoundAddressNFT boundAddressNFT);
  event ChainAdded(uint16 indexed);
  event ChainDeleted(uint16 indexed);

  IntermediateFactory public intermediateFactory;

  string public metaUri;

  mapping(bytes32 => bool) private hashUsed;
  mapping(bytes32 => address) private whoCommited;
  mapping(uint256 => bytes32) public tokenIdToSalt;
  mapping(uint16 => bool) public chainsToMint;

  mapping(bytes32 => uint256) public hashCommitedAtBlock;
  // mapping(uint256 => uint256) public deployPrices;

  BoundAddressNFT public boundAddressNFT;

  uint256[50] _____gap;

  event Modified();

  function modify() external { // 0x64cf33b8
    // code for modifying while upgrading
    chainsToMint[145] = true;
    emit ChainAdded(145);
    emit Modified();
  }

  function initialize(
    IntermediateFactory _intermediateFactory
  ) external initializer {
    __ERC721_init("Address NFT", "ADDR");
    __ERC721Enumerable_init();
    __Ownable_init();

    intermediateFactory = _intermediateFactory;
    emit SetIntermediateFactory(_intermediateFactory);
  }

  function setMetaUri(string calldata _metaUri) external onlyOwner {
    metaUri = _metaUri;
  }

  function toggleChainToMint(uint16 chainId, bool toggle) public onlyOwner {
    chainsToMint[chainId] = toggle;
    if (toggle) {
      emit ChainAdded(chainId);
    } else {
      emit ChainDeleted(chainId);
    }
  }

  function commit(bytes32 _hash) external {
    if (hashUsed[_hash] != false) revert UsedHash();
    if (whoCommited[_hash] != address(0)) revert CommittedHash();
    whoCommited[_hash] = msg.sender;
    hashCommitedAtBlock[_hash] = block.number;
    emit Commit(msg.sender, _hash);
  }

  function saltUsed(bytes32 salt) external view returns (bool used) {
    address addressPrecomputed = _precompute(address(this), salt);
    uint256 tokenId = uint256(uint160(addressPrecomputed));
    return tokenIdToSalt[tokenId] != 0;
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
    if (hashCommitedAtBlock[_hash] == block.number) {
      revert SameBlockReveal();
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

  function _deployIntermediateFactory(bytes32 salt) internal returns (IntermediateFactory) {
    address cloneAddress = UpgradeableCloneDeterministic(salt);
    (bool success, ) = cloneAddress.call(abi.encode(intermediateFactory));
    require(success); // TODO
    return IntermediateFactory(cloneAddress);
  }

  function _deploy(bytes32 salt, bytes memory code) internal returns (address) {
    address cloneAddress = UpgradeableCloneDeterministic(salt);
    (bool success, ) = cloneAddress.call(abi.encode(intermediateFactory));
    require(success); // TODO
    IntermediateFactory intermediateFactoryClone = IntermediateFactory(cloneAddress);

    return intermediateFactoryClone.deploy(code); // deploy from factory using create opcode (not create2)
  }

  modifier manageTokens(uint256 tokenId) {
    bool forBound = false;
    if (_exists(tokenId)) {
      if (ownerOf(tokenId) != msg.sender) {
        revert WrongOwner();
      }
    } else {
      if (boundAddressNFT.ownerOf(tokenId) != msg.sender) {
        // also throw if not exists
        revert WrongOwner();
      } else {
        forBound = true;
      }
    }
    _;
    if (!forBound) {
      _burn(tokenId);
      boundAddressNFT.mint(msg.sender, tokenId, true);
    } else {
      boundAddressNFT.setDeployed(tokenId);
    }
  }

  function deploy(
    uint256 tokenId,
    bytes memory code
  ) external manageTokens(tokenId) returns (address deployedAddress) {
    bytes32 salt = tokenIdToSalt[tokenId];
    IntermediateFactory intermediateFactoryClone = _deployIntermediateFactory(salt);
    deployedAddress = intermediateFactoryClone.deploy(code);
  }

  function deployTransparentProxy(
    uint256 tokenId,
    address logic,
    address admin,
    bytes calldata data
  ) external manageTokens(tokenId) returns (address deployedAddress) {
    bytes32 salt = tokenIdToSalt[tokenId];
    IntermediateFactory intermediateFactoryClone = _deployIntermediateFactory(salt);
    deployedAddress = intermediateFactoryClone.deployTransparentProxy(logic, admin, data);
  }

  function bind(uint256 tokenId) external {
    if (ownerOf(tokenId) != msg.sender) {
      revert WrongOwner();
    }
    _burn(tokenId);
    boundAddressNFT.mint(msg.sender, tokenId, false);
  }

  function mintCrosschain(uint16 chainId, uint256 tokenId) external payable {
    if (chainsToMint[chainId] == false) {
      revert CannotSendToChain();
    }
    if (boundAddressNFT.ownerOf(tokenId) != msg.sender) {
      revert WrongOwner();
    }
    ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(0x3c2269811836af69497E5F486A85D7316753cf62);
    bytes memory data = abi.encode(msg.sender, tokenIdToSalt[tokenId]);
    bytes memory remoteAndLocalAddresses = abi.encodePacked(address(this), address(this));
      endpoint.send{ value: msg.value }(
      chainId,
      remoteAndLocalAddresses,
      data,
      payable(msg.sender),
      address(0x0),
      bytes("")
    );
  }

  // override ERC721 methods
  function _baseURI() internal view override returns (string memory) {
    return metaUri;
  }

  function setIntermediateFactory(IntermediateFactory _intermediateFactory) external onlyOwner {
    intermediateFactory = _intermediateFactory;
    emit SetIntermediateFactory(_intermediateFactory);
  }

  function setBoundAddressNFT(BoundAddressNFT _boundAddressNFT) external onlyOwner {
    boundAddressNFT = _boundAddressNFT;
    emit SetBoundAddressNFT(_boundAddressNFT);
  }
}
