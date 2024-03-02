// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Constants} from "./Constants.sol";
import {IntermediateFactory} from "./IntermediateFactory.sol";
import {BoundAddressNFT} from "./BoundAddressNFT.sol";
import "./LzAppUpgradeable/NonblockingLzAppUpgradeable.sol";
// import "./LzAppUpgradeable/interfaces/ILayerZeroEndpoint.sol";

contract SecondaryMainFactory is
  NonblockingLzAppUpgradeable,
  Constants
{
  event SetIntermediateFactory(IntermediateFactory intermediateFactory);
  event SetBoundAddressNFT(BoundAddressNFT boundAddressNFT);

  error WrongChain(uint256);

  IntermediateFactory public intermediateFactory;

  BoundAddressNFT public boundAddressNFT;

  mapping(uint256 => bytes32) public tokenIdToSalt;

  uint256[50] _____gap;

  event Modified();

  function modify() external { // 0x64cf33b8
    // code for modifying while upgrading
    // lzEndpoint = ILayerZeroEndpoint(0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7);
    emit Modified();
  }

  function initialize(
    IntermediateFactory _intermediateFactory,
    address lzEndpoint
  ) external initializer {
    __Ownable_init();
    __LzApp_init(lzEndpoint);

    intermediateFactory = _intermediateFactory;
    emit SetIntermediateFactory(_intermediateFactory);
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory /*_srcAddress*/,
    uint64, /*_nonce*/
    bytes memory _payload
  ) internal override {
    if (_srcChainId != 109) {
      revert WrongChain(_srcChainId);
    }

    (address owner, bytes32 salt) = abi.decode(_payload, (address, bytes32));
    address addressPrecomputed = _precompute(address(this), salt);
    uint256 tokenId = uint256(uint160(addressPrecomputed));
    if (tokenIdToSalt[tokenId] == 0) {
      boundAddressNFT.mint(owner, tokenId, false);
      tokenIdToSalt[tokenId] = salt;
      emit Mint(msg.sender, tokenId, salt, addressPrecomputed);
    }
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

  modifier manageTokens(uint256 tokenId) { // TODO unit test
    if (boundAddressNFT.ownerOf(tokenId) != msg.sender) {
      // also throws if not exists
      revert WrongOwner();
    }
    _;
    boundAddressNFT.setDeployed(tokenId);
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

  function deployErc20(
    uint256 tokenId,
    address admin,
    string memory name,
    string memory symbol,
    uint256 premintAmount
  ) external manageTokens(tokenId) returns (address deployedAddress) {
    bytes32 salt = tokenIdToSalt[tokenId];
    IntermediateFactory intermediateFactoryClone = _deployIntermediateFactory(salt);
    deployedAddress = intermediateFactoryClone.deployErc20(admin, name, symbol, premintAmount);
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
