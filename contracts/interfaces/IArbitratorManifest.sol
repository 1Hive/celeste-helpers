// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface IArbitratorManifest {
    event PartiesSet(
        uint256 indexed disputeId,
        address indexed defendant,
        address indexed challenger
    );
    event RepStateSet(
        address indexed account,
        address indexed rep,
        bool isActive
    );
    event RecusalSet(
        address indexed rep,
        address indexed client,
        bool recused
    );

    function setPartiesOf(uint256 _disputeId, address _defendant, address _challenger) external;
    function setRepStatus(address _rep, bool _isActive) external;
    function setRecused(address _client, bool _recuseSelf) external;
    function isRepOf(address _account, address _rep) external view returns (bool isRep);
    function defendantOf(uint256 _disputeId) external view returns (address defendant);
    function challengerOf(uint256 _disputeId) external view returns (address challenger);
    function recusedFor(address _rep, address _client) external view returns (bool isRecused);
    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        external view returns (bool canSubmit, address submittingFor);
}
