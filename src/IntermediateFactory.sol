// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./deployable/AddressMarketERC20.sol";

contract IntermediateFactory {
  event Erc20Deployed(AddressMarketERC20);

  function deploy(bytes memory code) external returns (address addr) {
    assembly {
      addr := create(0, add(code, 0x20), mload(code))
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
  }

  function deployTransparentProxy(address logic, address admin) external returns (address addr) {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(logic, admin, "");
    return address(proxy);
  }

  // function deployErc20(address admin, string memory name, string memory symbol) external returns (address addr) {
  //   AddressMarketERC20 token = new AddressMarketERC20(admin, name, symbol);
  //   emit Erc20Deployed(token); // backend should get it and verify
  // }
}
