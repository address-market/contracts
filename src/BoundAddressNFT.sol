// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721EnumerableUpgradeable} from "openzeppelin/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin/access/OwnableUpgradeable.sol";

contract BoundAddressNFT is ERC721EnumerableUpgradeable, OwnableUpgradeable {
  error WrongCaller();
  error NotAnOwner();
  error NotTransferable();

  address public mainFactory;
  string public metaUri;
  mapping (uint256 => bool) public deployed;

  uint256[50] _____gap;

  function initialize(address _mainFactory) external initializer {
    __ERC721_init("Bound Address NFT", "BOUND");
    mainFactory = _mainFactory;
    __ERC721Enumerable_init();
    __Ownable_init();
  }

  function setMetaUri(string calldata _metaUri) external onlyOwner {
    metaUri = _metaUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return metaUri;
  }

  function mint(address owner, uint256 tokenId, bool isDeployed) external {
    if (msg.sender != mainFactory) {
      revert WrongCaller();
    }
    deployed[tokenId] = isDeployed;
    _mint(owner, tokenId);
  }

  function burn(uint256 tokenId) external {
    if (msg.sender != ownerOf(tokenId)) {
      revert NotAnOwner();
    }
    _burn(tokenId);
  }

  function tokenOfOwnerByIndexExtended(address owner, uint256 index) external view returns (uint256 tokenId, bool isDeployed) {
    tokenId = tokenOfOwnerByIndex(owner, index);
    isDeployed = deployed[tokenId];
  }

  // make not transferable
  function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    if (from != address(0) && to != address(0)) {
      revert NotTransferable();
    }
  }
}