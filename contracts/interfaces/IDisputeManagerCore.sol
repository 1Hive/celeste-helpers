// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface IDisputeManagerCore {
    event NewDispute(
        uint256 indexed disputeId,
        address indexed subject,
        uint64 indexed draftTermId,
        uint64 jurorsNumber,
        bytes metadata
    );
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes evidence);
    event EvidencePeriodClosed(uint256 indexed disputeId, uint64 indexed termId);
    event RulingComputed(uint256 indexed disputeId, uint8 indexed ruling);
}
