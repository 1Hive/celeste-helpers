// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/IArbitrator.sol";
import "./manifest/IArbitratorManifest.sol";

abstract contract Disputable {
    uint256 internal constant RULING_REFUSED = 2;
    uint256 internal constant RULING_AGAINST_ACTION = 3;
    uint256 internal constant RULING_FOR_ACTION = 4;

    IArbitrator immutable public arbitrator;
    IArbitratorManifest immutable public arbitratorManifest;

    constructor(IArbitrator _arbitrator, IArbitratorManifest _arbitratorManifest) {
        arbitrator = _arbitrator;
        arbitratorManifest = _arbitratorManifest;
    }

    function submitEvidenceFor(
        uint256 _disputeId,
        bytes calldata _evidence
    )
        external virtual
    {
        (bool canSubmitEvidence, address submittingFor) =
            arbitratorManifest.canSubmitEvidenceFor(msg.sender, _disputeId);
        require(canSubmitEvidence, "Disputable: not part of dispute");
        arbitrator.submitEvidence(_disputeId, submittingFor, _evidence);
    }

    function _createDisputeAgainst(
        address _defendant,
        address _plaintiff,
        bytes memory _metadata
    )
        internal virtual returns (uint256)
    {
        uint256 disputeId = arbitrator.createDispute(2, _metadata);
        arbitratorManifest.setPartiesOf(disputeId, _defendant, _plaintiff);
        return disputeId;
    }
}
