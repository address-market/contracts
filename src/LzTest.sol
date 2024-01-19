// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {NonblockingLzApp} from "solidity-examples/lzApp/NonblockingLzApp.sol";
import {ERC721Enumerable, ERC721} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract LzTest is NonblockingLzApp, ERC721Enumerable {
  error WrongChain(uint256);
  event SrcAddress(bytes);

  constructor(address _endpoint) NonblockingLzApp(_endpoint) ERC721("test LZ", "TLZ") {}

  /// @dev Internal function to handle incoming Ping messages.
  /// @param _srcChainId The source chain ID from which the message originated.
  /// @param _payload The payload of the incoming message.
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64, /*_nonce*/
    bytes memory _payload
  ) internal override {
    if (_srcChainId != 109) {
      revert WrongChain(_srcChainId);
    }
    emit SrcAddress(_srcAddress);

    (address owner, uint256 tokenId) = abi.decode(_payload, (address, uint256));
    _mint(owner, tokenId);
  }

  // allow this contract to receive ether
  receive() external payable {}
}
