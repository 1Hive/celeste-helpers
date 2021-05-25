// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/ICourt.sol";

abstract contract Disputable {
    ICourt immutable public court;
    mapping(address => mapping(address => bool)) internal isRepresentativeOf;
    mapping(uint256 => address) internal defendantOf;
    mapping(uint256 => address) internal plaintiffOf;

    event RepresentativeStatusSet(
        address indexed representative,
        address indexed account,
        bool isRepresentative
    );

    constructor(ICourt _court) {
        court = _court;
    }

    function setRepresentative(address _representative, bool _isRepresentative)
        external
    {
        require(
            _representatives[_representative][msg.sender] != _isRepresentative,
            "Disputable: Repr. already set"
        );
        _representatives[_representative][msg.sender] = _isRepresentative;
        emit RepresentativeStatusSet(_representative, msg.sender, _isRepresentative);
    }

    function submitEvidenceFor(
        uint256 _disputeId,
        address _party,
        bytes calldata _evidence
    )
        external
    {
        address defendant = defendantOf[_disputeId];
        address plaintiff = plaintiffOf[_disputeId];
        bool isDefendant = msg.sender == defendant || isRepresentativeOf[msg.sender][defendant];
        bool isPlaintiff = msg.sender == plaintiff || isRepresentativeOf[msg.sender][plaintiff];
        require(isDefendant || isPlaintiff, "Disputable: Not part of dispute");
        court.submitEvidence(_disputeId, isDefendant ? defendant : plaintiff, _evidence);
    }

    function _createDisputeAgainst(
        address _defendant,
        address _plaintiff,
        bytes memory _metadata
    )
        internal
    {
        uint256 disputeId = court.createDispute(2, _metadata);
        defendantOf[disputeId] = _defendant;
        plaintiffOf[disputeId] = _plaintiff;
    }
}
