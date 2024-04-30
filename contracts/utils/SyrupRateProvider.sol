// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ISyrupRateProvider } from "../interfaces/ISyrupRateProvider.sol";

import { IPoolLike } from "../interfaces/Interfaces.sol";

contract SyrupRateProvider is ISyrupRateProvider {

    address immutable public override pool;

    constructor(address pool_) {
        pool = pool_;
    }

    function getRate() external view override returns (uint256) {
        return IPoolLike(pool).convertToExitAssets(1e18) * 1e12;  // Scale up from 1e6 to 1e18
    }

}
