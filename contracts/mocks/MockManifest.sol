// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../manifest/CourtManifestCore.sol";
import "./IMockCourt.sol";

contract MockManifest is CourtManifestCore {
    IMockCourt internal immutable mockCourt;

    constructor(IMockCourt _mockCourt) {
        mockCourt = _mockCourt;
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view override returns (address subject)
    {
        subject = mockCourt.getSubjectOf(_disputeId);
    }
}
