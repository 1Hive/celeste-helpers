// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDisputeManagerCore.sol";

interface IDisputeManager is IDisputeManagerCore {
    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    enum AdjudicationState {
        Invalid,
        Committing,
        Revealing,
        Appealing,
        ConfirmingAppeal,
        Ended
    }

    function createDispute(address _subject, uint8 _possibleRulings, bytes calldata _metadata) external returns (uint256);
    function submitEvidence(address _subject, uint256 _disputeId, address _submitter, bytes calldata _evidence) external;
    function closeEvidencePeriod(address _subject, uint256 _disputeId) external;
    function draft(uint256 _disputeId) external;
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;
    function computeRuling(uint256 _disputeId) external returns (address subject, uint8 finalRuling);
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _jurorsToSettle) external;
    function settleReward(uint256 _disputeId, uint256 _roundId, address _juror) external;
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external;
    function getDisputeFees() external view returns (IERC20 feeToken, uint256 feeAmount);
    function getDispute(uint256 _disputeId)
        external view returns (
            address subject,
            uint8 possibleRulings,
            DisputeState state,
            uint8 finalRuling,
            uint256 lastRoundId,
            uint64 createTermId
        );
    function getRound(uint256 _disputeId, uint256 _roundId)
        external view returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 jurorsNumber,
            uint64 selectedJurors,
            uint256 jurorFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentJurors,
            AdjudicationState state
        );
    function getAppeal(uint256 _disputeId, uint256 _roundId)
        external view returns (
            address maker,
            uint64 appealedRuling,
            address taker,
            uint64 opposedRuling
        );
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId)
        external view returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundJurorsNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 jurorFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );
    function getJuror(uint256 _disputeId, uint256 _roundId, address _juror)
        external view returns (
            uint64 weight,
            bool rewarded
        );


    event DisputeStateChanged(uint256 indexed disputeId, DisputeState indexed state);
    event JurorDrafted(uint256 indexed disputeId, uint256 indexed roundId, address indexed juror);
    event RulingAppealed(uint256 indexed disputeId, uint256 indexed roundId, uint8 ruling);
    event RulingAppealConfirmed(uint256 indexed disputeId, uint256 indexed roundId, uint64 indexed draftTermId, uint256 jurorsNumber);
    event PenaltiesSettled(uint256 indexed disputeId, uint256 indexed roundId, uint256 collectedTokens);
    event RewardSettled(uint256 indexed disputeId, uint256 indexed roundId, address juror, uint256 tokens, uint256 fees);
    event AppealDepositSettled(uint256 indexed disputeId, uint256 indexed roundId);
    event MaxJurorsPerDraftBatchChanged(uint64 previousMaxJurorsPerDraftBatch, uint64 currentMaxJurorsPerDraftBatch);
}
