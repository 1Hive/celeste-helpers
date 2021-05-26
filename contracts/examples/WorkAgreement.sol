// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICourt.sol";
import "../manifest/ICourtManifest.sol";
import "../Disputable.sol";

contract WorkAgreement is Disputable {
    using SafeERC20 for IERC20;

    bytes32 public immutable agreementCommitment;
    uint256 public immutable releaseAt;
    address public immutable employer;
    address public immutable contractor;

    bool public beingDisputed;
    uint256 public disputeId;

    constructor(
        ICourt _court,
        ICourtManifest _courtManifest,
        bytes32 _agreementCommitment,
        uint256 _releaseAt,
        address _contractor
    )
        Disputable(_court, _courtManifest) payable
    {
        agreementCommitment = _agreementCommitment;
        releaseAt = _releaseAt;
        employer = msg.sender;
        contractor = _contractor;
    }

    function releasePayment() external {
        require(!beingDisputed, "WorkAgreement: being disputed");
        require(msg.sender == contractor, "WorkAgreement: not contractor");
        require(block.timestamp >= releaseAt, "WorkAgreement: not yet unlocked");
        selfdestruct(payable(contractor));
    }

    function dispute(bytes32 _salt, bytes calldata _agreementMetadata) external {
        require(!beingDisputed, "WorkAgreement: already disputed");
        require(msg.sender == employer, "WorkAgreement: not employer");
        require(
            agreementCommitment == keccak256(abi.encode(_salt, _agreementMetadata)),
            "WorkAgreement: invalid agreement"
        );
        beingDisputed = true;
        (, IERC20 feeToken, uint256 feeAmount) = court.getDisputeFees();
        feeToken.safeTransferFrom(msg.sender, address(this), feeAmount);
        feeToken.safeApprove(court.getDisputeManager(), feeAmount);
        disputeId = _createDisputeAgainst(contractor, employer, _agreementMetadata);
    }

    function settleDispute() external {
        require(beingDisputed, "WorkAgreement: Not being disputed");
        (, uint256 ruling) = court.rule(disputeId);
        selfdestruct(payable(ruling == RULING_AGAINST_ACTION ? employer : contractor));
    }
}
