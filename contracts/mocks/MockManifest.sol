// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../manifest/ArbitratorManifestCore.sol";
import "./IMockArbitrator.sol";

contract MockManifest is ArbitratorManifestCore {
    IMockArbitrator public immutable disputeManager;

    constructor(address _mockArbitrator) {
        disputeManager = IMockArbitrator(_mockArbitrator);
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view override returns (address subject)
    {
        subject = disputeManager.getSubjectOf(_disputeId);
    }
}
