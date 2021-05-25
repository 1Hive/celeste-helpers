// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/ICourtManifest.sol";
import "./interfaces/IDisputeManager.sol";

contract CourtManifest is ICourtManifest {
    IDisputeManager public immutable disputeManager;
    mapping(address => mapping(address => bool)) public override isRepOf;
    mapping(uint256 => address) public override defendantOf;
    mapping(uint256 => address) public override plaintiffOf;

    constructor(IDisputeManager _disputeManager) {
        disputeManager = _disputeManager;
    }

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _plaintiff
    )
        external override
    {
        (address subject,,,,,) = disputeManager.getDispute(_disputeId);
        require(msg.sender == subject, "CourtManifest: not subject");
        defendantOf[_disputeId] = _defendant;
        defendantOf[_disputeId] = _plaintiff;
        emit PartiesSet(_disputeId, _defendant, _plaintiff);
    }

    function setRepStatus(address _rep, bool _isActive) external override {
        require(isRepOf[msg.sender][_rep] != _isActive, "CourtManifest: already set");
        isRepOf[msg.sender][_rep] = _isActive;
        emit RepStateChanged(msg.sender, _rep, _isActive);
    }

    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        public view override returns (bool, address)
    {
        address defendant = defendantOf[_disputeId];
        if (defendant == _submitter || isRepOf[defendant][_submitter]) {
            return (true, defendant);
        }
        address plaintiff = plaintiffOf[_disputeId];
        if (plaintiff == _submitter || isRepOf[plaintiff][_submitter]) {
            return (true, plaintiff);
        }
        return (false, address(0));
    }
}
