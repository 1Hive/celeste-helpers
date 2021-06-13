// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IArbitrator.sol";
import "./manifest/IArbitratorManifest.sol";

abstract contract Disputable {
    using SafeERC20 for IERC20;

    uint256 internal constant RULING_REFUSED = 2;
    uint256 internal constant RULING_AGAINST_ACTION = 3;
    uint256 internal constant RULING_FOR_ACTION = 4;

    IArbitrator immutable public arbitrator;
    IArbitratorManifest immutable public arbitratorManifest;

    constructor(address _arbitrator, address _arbitratorManifest) {
        arbitrator = IArbitrator(_arbitrator);
        arbitratorManifest = IArbitratorManifest(_arbitratorManifest);
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

    function _prepareDisputeFee()
        internal returns(IERC20 feeToken, uint256 feeAmount)
    {
        address recipient;
        (recipient, feeToken, feeAmount) = arbitrator.getDisputeFees();
        feeToken.safeIncreaseAllowance(recipient, feeAmount);
    }

    function _prepareAndPullDisputeFeeFrom(address _feePayer) internal {
        (IERC20 feeToken, uint256 feeAmount) = _prepareDisputeFee();
        feeToken.safeTransferFrom(_feePayer, address(this), feeAmount);
    }

    function _getRulingOf(uint256 _disputeId) internal returns(uint256) {
        (address subject, uint256 ruling) = arbitrator.rule(_disputeId);
        require(subject == address(this), "Disputable: not dispute subject");
        return ruling;
    }

    function _createDisputeAgainst(
        address _defendant,
        address _challenger,
        bytes memory _metadata
    )
        internal virtual returns (uint256)
    {
        uint256 disputeId = arbitrator.createDispute(2, _metadata);
        arbitratorManifest.setPartiesOf(disputeId, _defendant, _challenger);
        return disputeId;
    }
}
