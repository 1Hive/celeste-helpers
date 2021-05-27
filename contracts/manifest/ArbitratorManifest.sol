// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../interfaces/IDisputeManager.sol";
import "./ArbitratorManifestCore.sol";

contract ArbitratorManifest is ArbitratorManifestCore {
    IDisputeManager public immutable disputeManager;

    constructor(IDisputeManager _disputeManager) {
        disputeManager = _disputeManager;
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view override returns (address subject)
    {
        (subject,,,,,) = disputeManager.getDispute(_disputeId);
    }
}
