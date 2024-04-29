// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ISyrupRateProvider {

    /**
     * @return The value of Pool Token in terms of the underlying
     */
    function getRate() external view returns (uint256);

    /**
     * @return The address of Pool contract
     */
    function pool() external view returns (address);

}

