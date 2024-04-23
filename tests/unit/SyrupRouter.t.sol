// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../../modules/forge-std/src/Test.sol";

import { SyrupRouter } from "../../contracts/SyrupRouter.sol";

import {
    MockERC20,
    MockPool,
    MockPoolManager,
    MockPoolPermissionManager
} from "../utils/Mocks.sol";

contract SyrupRouterTests is Test {

    address account = makeAddr("account");

    bytes32 functionId = "P:deposit";

    uint256 amount = 2;

    MockERC20                 asset;
    MockPoolManager           pm;
    MockPool                  pool;
    MockPoolPermissionManager ppm;

    SyrupRouter router;

    function setUp() public {
        asset = new MockERC20("USDC", "USDC", 6);
        ppm   = new MockPoolPermissionManager();
        pm    = new MockPoolManager(address(ppm));
        pool  = new MockPool("MaplePool", "MP", 18, address(asset), address(pm));

        router = new SyrupRouter(address(pool));

        asset.mint(account, amount);
    }

    function test_constructor_approveFails() external {
        asset.__setApproveReverts(true);

        vm.expectRevert("SR:C:APPROVE_FAIL");
        router = new SyrupRouter(address(pool));
    }

    function test_constructor_success() external {
        vm.expectCall(address(pool),  abi.encodeWithSelector(MockPool.asset.selector));
        vm.expectCall(address(pool),  abi.encodeWithSelector(MockPool.manager.selector));
        vm.expectCall(address(pm),    abi.encodeWithSelector(MockPoolManager.poolPermissionManager.selector));
        vm.expectCall(address(asset), abi.encodeWithSelector(MockERC20.approve.selector, address(pool), type(uint256).max));

        router = new SyrupRouter(address(pool));

        assertEq(router.asset(),                 address(asset));
        assertEq(router.pool(),                  address(pool));
        assertEq(router.poolManager(),           address(pm));
        assertEq(router.poolPermissionManager(), address(ppm));

        assertEq(asset.allowance(address(router), address(pool)), type(uint256).max);
    }

    function test_deposit_notAuthorized() external {
        ppm.__setHasPermission(false);

        vm.prank(account);
        vm.expectRevert("SR:D:NOT_AUTHORIZED");
        router.deposit(amount);
    }

    function test_deposit_transferFromFails_insufficientAmount() external {
        asset.burn(account, 1);

        vm.prank(account);
        vm.expectRevert("SR:D:TRANSFER_FROM_FAIL");
        router.deposit(amount);
    }

    function test_deposit_transferFromFails_insufficientApproval() external {
        vm.prank(account);
        asset.approve(address(router), amount - 1);

        vm.prank(account);
        vm.expectRevert("SR:D:TRANSFER_FROM_FAIL");
        router.deposit(amount);
    }

    function test_deposit_transferFails() external {
        pool.__setTransferReverts(true);

        vm.prank(account);
        asset.approve(address(router), amount);

        vm.prank(account);
        vm.expectRevert("SR:D:TRANSFER_FAIL");
        router.deposit(amount);
    }

    function test_deposit_success() external {
        vm.prank(account);
        asset.approve(address(router), amount);

        vm.expectCall(address(ppm),   abi.encodeWithSelector(MockPoolPermissionManager.hasPermission.selector, address(pm), account, functionId));
        vm.expectCall(address(asset), abi.encodeWithSelector(MockERC20.transferFrom.selector, account, address(router), amount));
        vm.expectCall(address(pool),  abi.encodeWithSelector(MockPool.deposit.selector, amount, address(router)));
        vm.expectCall(address(pool),  abi.encodeWithSelector(MockERC20.transfer.selector, account, amount));

        assertEq(asset.balanceOf(account),       amount);
        assertEq(asset.balanceOf(address(pool)), 0);

        assertEq(pool.balanceOf(account), 0);
        assertEq(pool.totalSupply(),      0);

        vm.prank(account);
        router.deposit(amount);

        assertEq(asset.balanceOf(account),       0);
        assertEq(asset.balanceOf(address(pool)), amount);

        assertEq(pool.balanceOf(account), amount);
        assertEq(pool.totalSupply(),      amount);
    }

}
