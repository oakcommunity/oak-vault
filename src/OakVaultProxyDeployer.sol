// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract OakVaultProxyDeployer {
    address public immutable oakVaultImpl;

    event OakVaultDeployed(address proxyAddress);

    constructor(
        address _oakVaultImpl,
        address _oakToken,
        address _usdcToken
    ) {
        oakVaultImpl = _oakVaultImpl;

        address oakVaultProxy;
        oakVaultProxy = address(
            new ERC1967Proxy(
                address(oakVaultImpl),
                abi.encodeWithSignature("initialize(address,address)", _oakToken, _usdcToken)
            )
        );
        emit OakVaultDeployed(oakVaultProxy);
    }
}
