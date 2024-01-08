// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * DustNFT is generated then NFTOption is burned
 */
contract DustNFT is ERC721, Ownable {
  error WrongCaller();
  error NotAnOwner();
  error NotTransferable();

  address immutable public nftOptions;
  string public metaUri;

  constructor(address _nftOptions) ERC721("DustNFT", "DUST") {
    nftOptions = _nftOptions;
  }

  function setMetaUri(string calldata _metaUri) external onlyOwner {
    metaUri = _metaUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return metaUri;
  }

  function mint(address owner, uint256 tokenId) external {
    if (msg.sender != nftOptions) {
      revert WrongCaller();
    }
    _mint(owner, tokenId);
  }

  function burn(uint256 tokenId) external {
    if (msg.sender != ownerOf(tokenId)) {
      revert NotAnOwner();
    }
    _burn(tokenId);
  }

  // make not transferable
  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    if (from != address(0) && to != address(0)) {
      revert NotTransferable();
    }
  }
}