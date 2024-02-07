// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AddressMarketERC20 is ERC20, Ownable {
  constructor(
    address owner,
    string memory name,
    string memory symbol
  ) ERC20(name, symbol) {
    _transferOwnership(owner);
  }

  function mint(address receiver, uint256 value) external onlyOwner {
    _mint(receiver, value);
  }

  function burn(uint256 value) external onlyOwner {
    _burn(msg.sender, value);
  }
}
