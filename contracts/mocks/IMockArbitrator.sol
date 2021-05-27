// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../interfaces/IArbitrator.sol";
import "../interfaces/IDisputeManagerCore.sol";

interface IMockArbitrator is IArbitrator, IDisputeManagerCore {
    function setRuling(uint256 _disputeId, uint256 _ruling) external;
    function getSubjectOf(uint256 _disputeId)
        external view returns (address);
}
