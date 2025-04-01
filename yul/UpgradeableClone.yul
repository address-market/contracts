object "UpgradeableClone" {
  code {
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      let impl := sload(0)
      switch impl
      case 0 { // first call - to add implementation
        sstore(0, calldataload(0))
      }
      default { // other calls - to act as a proxy
        calldatacopy(0, 0, calldatasize())
        let success := delegatecall(
          gas(),
          impl,
          0,
          calldatasize(),
          0,
          0
        )
        returndatacopy(0, 0, returndatasize())
        if iszero(success) {
          revert (0, returndatasize())
        }
        return (0, returndatasize())
      }
    }
  }
}

// 0x6034600d60003960346000f3fe6000548060008114602b573660008037600080366000855af43d6000803e806026573d6000fd5b3d6000f35b6000356000555050
