// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../interfaces/IArbitratorManifest.sol";

abstract contract ArbitratorManifestCore is IArbitratorManifest {
    mapping(address => mapping(address => bool)) public override isRepOf;
    mapping(address => mapping(address => bool)) public override recusedFor;
    mapping(uint256 => address) public override defendantOf;
    mapping(uint256 => address) public override challengerOf;

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    )
        external override
    {
        require(msg.sender == _getSubjectOf(_disputeId), "ArbitratorManifest: not subject");
        defendantOf[_disputeId] = _defendant;
        challengerOf[_disputeId] = _challenger;
        emit PartiesSet(_disputeId, _defendant, _challenger);
    }

    function setRepStatus(address _rep, bool _isActive) external override {
        _setRepStatus(msg.sender, _rep, _isActive);
    }

    function setRecused(address _client, bool _recuseSelf) external override {
        if (_recuseSelf) {
            _setRepStatus(_client, msg.sender, false);
        }
        recusedFor[msg.sender][_client] = _recuseSelf;
        emit RecusalSet(msg.sender, _client, _recuseSelf);
    }

    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        public view override returns (bool, address)
    {
        address defendant = defendantOf[_disputeId];
        if (defendant == _submitter) {
            return (true, defendant);
        }
        address challenger = challengerOf[_disputeId];
        if (isRepOf[defendant][_submitter]) {
            require(!isRepOf[challenger][_submitter], "ArbitratorManifest: rep conflict");
            return (true, defendant);
        }
        if (challenger == _submitter || isRepOf[challenger][_submitter]) {
            return (true, challenger);
        }
        return (false, address(0));
    }

    function _setRepStatus(address _client, address _rep, bool _isActive) internal {
        require(!_isActive || !recusedFor[_rep][_client], "ArbitratorManifest: rep recused");
        isRepOf[msg.sender][_rep] = _isActive;
        emit RepStateSet(msg.sender, _rep, _isActive);
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view virtual returns (address subject);
}
