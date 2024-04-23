// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { ISyrupRouter } from "./interfaces/ISyrupRouter.sol";

import {
    IERC20Like,
    IPoolLike,
    IPoolManagerLike,
    IPoolPermissionManagerLike
} from "./interfaces/Interfaces.sol";

contract SyrupRouter is ISyrupRouter {

    address immutable public override asset;
    address immutable public override pool;
    address immutable public override poolManager;
    address immutable public override poolPermissionManager;

    constructor(address pool_) {
        pool = pool_;

        // Get the addresses of all the associated contracts.
        address asset_ = asset = IPoolLike(pool_).asset();
        address poolManager_ = poolManager = IPoolLike(pool_).manager();

        poolPermissionManager = IPoolManagerLike(poolManager_).poolPermissionManager();

        // Perform an infinite approval.
        require(ERC20Helper.approve(asset_, pool_, type(uint256).max), "SR:C:APPROVE_FAIL");
    }

    function deposit(uint256 amount_) external override {
        // Check the caller has permission to deposit into the pool.
        require(
            IPoolPermissionManagerLike(poolPermissionManager).hasPermission(poolManager, msg.sender, "P:deposit"),
            "SR:D:NOT_AUTHORIZED"
        );

        // Pull assets from the caller to the router.
        require(ERC20Helper.transferFrom(asset, msg.sender, address(this), amount_), "SR:D:TRANSFER_FROM_FAIL");

        // Deposit assets into the pool and receive the shares personally.
        address pool_   = pool;
        uint256 shares_ = IPoolLike(pool_).deposit(amount_, address(this));

        // Route shares back to the caller.
        require(ERC20Helper.transfer(pool_, msg.sender, shares_), "SR:D:TRANSFER_FAIL");
    }

}
