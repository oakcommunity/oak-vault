// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { OakVault } from "./OakVault.sol";

/**
 * @title OakVaultProxyDeployer
 * @author taayyohh
 * @notice A contract to deploy an instance of OakVault using the ERC1967 proxy pattern.
 */
contract OakVaultProxyDeployer {
    /// @notice Address of the OakVault implementation contract.
    address public immutable oakVaultImpl;

    /// @notice Address of the OakVault proxy contract.
    address public oakVaultProxy;

    /// @notice Event emitted when a new OakVault proxy is deployed.
    event OakVaultDeployed(address proxyAddress);

    /**
     * @dev Constructor that deploys a new instance of OakVault using a proxy.
     * @param _oakVaultImpl Address of the OakVault implementation contract.
     * @param _oakToken Address of the OAK token contract.
     * @param _usdcToken Address of the USDC token contract.
     */
    constructor(
        address _oakVaultImpl,
        address _oakToken,
        address _usdcToken
    ) {
        oakVaultImpl = _oakVaultImpl;

        oakVaultProxy = address(
            new ERC1967Proxy(
                address(oakVaultImpl),
                abi.encodeWithSignature("initialize(address,address)", _oakToken, _usdcToken)
            )
        );
        OakVault(oakVaultProxy).transferOwnership(msg.sender);
        emit OakVaultDeployed(oakVaultProxy);
    }
}
