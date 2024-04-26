// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

// TODO: Add NatSpec documentation (events if needed).
interface ISyrupRouter {

    function asset() external view returns (address asset);

    function deposit(uint256 assets) external;

    function depositWithPermit(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function pool() external view returns (address pool);

    function poolManager() external view returns (address poolManager);

    function poolPermissionManager() external view returns (address poolPermissionManager);

}

