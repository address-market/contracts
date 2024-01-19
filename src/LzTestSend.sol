// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface ILayerZeroEndpoint {
  function send(
    uint16 _dstChainId,
    bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;
}

contract LzTestSend {
  error WrongChain(uint256);
  event SrcAddress(bytes);

  function send(address owner, uint256 tokenId) payable external {
    ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(0x3c2269811836af69497E5F486A85D7316753cf62);
    uint16 harmonyId = 116;
    bytes memory data = abi.encode(owner, tokenId);
    address remoteAddress = 0xc1810D57f63145D7Be7F0Cd15596347E78B20320;
    address localAddress = address(this);
    bytes memory remoteAndLocalAddresses = abi.encodePacked(remoteAddress, localAddress);
    endpoint.send{ value: msg.value }(
      harmonyId,
      remoteAndLocalAddresses,
      data,
      payable(msg.sender),
      address(0x0),
      bytes("")
    );
  }

  receive() external payable {}
}
