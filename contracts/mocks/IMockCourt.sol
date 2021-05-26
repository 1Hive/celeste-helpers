// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../interfaces/ICourt.sol";
import "../interfaces/IDisputeManagerCore.sol";

interface IMockCourt is ICourt, IDisputeManagerCore {
    function setRuling(uint256 _disputeId, uint256 _ruling) external;
    function getSubjectOf(uint256 _disputeId)
        external view returns (address);
}
