// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/ICourt.sol";
import "./manifest/ICourtManifest.sol";

abstract contract Disputable {
    uint256 internal constant RULING_REFUSED = 2;
    uint256 internal constant RULING_AGAINST_ACTION = 3;
    uint256 internal constant RULING_FOR_ACTION = 4;

    ICourt immutable public court;
    ICourtManifest immutable public courtManifest;

    constructor(ICourt _court, ICourtManifest _courtManifest) {
        court = _court;
        courtManifest = _courtManifest;
    }

    function submitEvidenceFor(
        uint256 _disputeId,
        bytes calldata _evidence
    )
        external virtual
    {
        (bool canSubmitEvidence, address submittingFor) =
            courtManifest.canSubmitEvidenceFor(msg.sender, _disputeId);
        require(canSubmitEvidence, "Disputable: not part of dispute");
        court.submitEvidence(_disputeId, submittingFor, _evidence);
    }

    function _createDisputeAgainst(
        address _defendant,
        address _plaintiff,
        bytes memory _metadata
    )
        internal virtual returns (uint256)
    {
        uint256 disputeId = court.createDispute(2, _metadata);
        courtManifest.setPartiesOf(disputeId, _defendant, _plaintiff);
        return disputeId;
    }
}
