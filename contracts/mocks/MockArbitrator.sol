// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMockArbitrator.sol";

contract MockArbitrator is IMockArbitrator, Ownable {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    struct Dispute {
        address subject;
        uint256 ruling; // 0 if no ruling available, 2-4 ruling computed, 5-7 ruling set
        bool evidencePeriodClosed;
    }

    uint256 internal FEE_AMOUNT = 1e18;
    IERC20 internal immutable feeToken;
    Dispute[] internal disputes;

    constructor(IERC20 _feeToken) Ownable() {
        feeToken = _feeToken;
    }

    modifier onlySubjectOf(uint256 _disputeId) {
        require(msg.sender == disputes[_disputeId].subject, "DM_SUBJECT_NOT_DISPUTE_SUBJECT");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes.length > _disputeId, "ERROR_DISPUTE_DOES_NOT_EXIST");
        _;
    }

    function createDispute(uint256 _possibleRulings, bytes calldata _metadata)
        external override returns (uint256)
    {
        require(_possibleRulings == 2, "DM_INVALID_RULING_OPTIONS");
        uint256 newDisputeId = disputes.length;
        disputes.push();
        disputes[newDisputeId].subject = msg.sender;
        feeToken.safeTransferFrom(msg.sender, address(this), FEE_AMOUNT);
        emit NewDispute(newDisputeId, msg.sender, 0, 3, _metadata);
        return newDisputeId;
    }

    function submitEvidence(
        uint256 _disputeId,
        address _submitter,
        bytes calldata _evidence
    )
        external override disputeExists(_disputeId) onlySubjectOf(_disputeId)
    {
        emit EvidenceSubmitted(_disputeId, _submitter, _evidence);
    }

    function closeEvidencePeriod(uint256 _disputeId)
        external override onlySubjectOf(_disputeId)
    {
        require(!disputes[_disputeId].evidencePeriodClosed, "DM_EVIDENCE_PERIOD_IS_CLOSED");
        disputes[_disputeId].evidencePeriodClosed = true;
        emit EvidencePeriodClosed(_disputeId, 0);
    }

    function rule(uint256 _disputeId)
        external override disputeExists(_disputeId) returns (address, uint256)
    {
        Dispute storage dispute = disputes[_disputeId];
        uint256 ruling = dispute.ruling;
        require(ruling != 0, "DM_INVALID_ADJUDICATION_STATE");
        if (ruling > 4) {
            ruling -= 3;
            dispute.ruling = ruling;
            emit RulingComputed(_disputeId, ruling.toUint8());
        }
        return (dispute.subject, ruling);
    }

    function setRuling(uint256 _disputeId, uint256 _ruling)
        external override disputeExists(_disputeId) onlyOwner
    {
        require(2 <= _ruling && _ruling <= 4, "MockArbitrator: invalid ruling");
        disputes[_disputeId].ruling = _ruling + 3;
    }

    function getSubjectOf(uint256 _disputeId)
        external view override returns (address)
    {
        return disputes[_disputeId].subject;
    }

    function getDisputeFees()
        external view override returns (
            address recipient,
            IERC20 feeToken_,
            uint256 feeAmount
        )
    {
        recipient = address(0);
        feeToken_ = feeToken;
        feeAmount = FEE_AMOUNT;
    }

    function getDisputeManager() external view override returns (address) {
        return address(this);
    }
}
