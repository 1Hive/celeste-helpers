// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../interfaces/IArbitratorManifest.sol";

abstract contract ArbitratorManifestCore is IArbitratorManifest {
    mapping(address => mapping(address => bool)) public override isRepOf;
    mapping(address => mapping(address => bool)) public override canRepresent;
    mapping(uint256 => address) public override defendantOf;
    mapping(uint256 => address) public override challengerOf;

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    )
        external override
    {
        require(msg.sender == _getSubjectOf(_disputeId), "ArbManifest: not subject");
        require(_defendant != _challenger, "ArbManifest: party conflict");
        defendantOf[_disputeId] = _defendant;
        challengerOf[_disputeId] = _challenger;
        emit PartiesSet(_disputeId, _defendant, _challenger);
    }

    /**
      Sets whether the `_client` is allowed to set the `msg.sender` as their
      representative. Potentially also resets the representative status to false

      @param _client the potential `_client` of the `msg.sender` for which to
      set the approval
      @param _allow whether the `msg.sender` is allowing the `_client` to set
      them as a representative
      @dev fires `AllowRepresentation` event
      @dev fires a `RepStateSet` if `_allow = false`
      @dev sets rep status to `false` if `_allow = false`
    */
    function allowRepresentation(address _client, bool _allow) external override {
        if (!_allow) {
            _setRepStatus(_client, msg.sender, false);
        }
        canRepresent[msg.sender][_client] = _allow;
        emit AllowRepresentation(msg.sender, _client, _allow);
    }

    /**
      Sets whether the `_rep` is to be a representative of the `msg.sender`

      @param _rep address of the representative for which to change the status
      @param _isActive whether `_rep` is to be a representative of `msg.sender`
      @dev fires a `RepStateSet` event
      @dev reverts if `canRepresent[_rep][msg.sender] = false`
    */
    function setRepStatus(address _rep, bool _isActive) external override {
        _setRepStatus(msg.sender, _rep, _isActive);
    }

    /**
      @dev will also return `false` if `msg.sender` is a representative of both
      the defendant and challenger
    */
    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        public view override returns (bool, address)
    {
        address defendant = defendantOf[_disputeId];
        bool isDefendant = defendant == _submitter || isRepOf[defendant][_submitter];
        address challenger = challengerOf[_disputeId];
        bool isChallenger = challenger == _submitter || isRepOf[challenger][_submitter];
        if (isDefendant != isChallenger) {
            return (true, isDefendant ? defendant : challenger);
        }
        return (false, address(0));
    }

    function _setRepStatus(address _client, address _rep, bool _isActive) internal {
        require(!_isActive || canRepresent[_rep][_client], "ArbManifest: cannot rep");
        isRepOf[_client][_rep] = _isActive;
        emit RepStateSet(_client, _rep, _isActive);
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view virtual returns (address subject);
}
