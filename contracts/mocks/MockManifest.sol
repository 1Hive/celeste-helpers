// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../manifest/ArbitratorManifestCore.sol";
import "./IMockArbitrator.sol";

contract MockManifest is ArbitratorManifestCore {
    IMockArbitrator internal immutable mockArbitrator;

    constructor(address _mockArbitrator) {
        mockArbitrator = IMockArbitrator(_mockArbitrator);
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view override returns (address subject)
    {
        subject = mockArbitrator.getSubjectOf(_disputeId);
    }
}
