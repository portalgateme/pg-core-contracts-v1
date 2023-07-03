// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IDegradable.sol";
import "../interfaces/IPolicyManager.sol";
import "../consent/Consent.sol";

/**
 * @title Degradable
 * @dev A contract that allows services to specify how to mitigate service interuptions
 * using policy-specific parameters.
 */

contract Degradable is IDegradable, Consent {
    uint256 private constant FIRST_CONFIGURABLE_POLICY = 1;
    uint256 private constant MAX_DEGRATION_PERIOD = 60 days;
    uint256 private constant MAX_DEGRATION_FRESHNESS_PERIOD = 365 days * 50;
    uint256 private constant MAX_CONSENT_DEADLINE = 10 days;
    address private constant NULL_ADDRESS = address(0);

    bytes32 public constant override ROLE_SERVICE_SUPERVISOR = keccak256(abi.encodePacked("supervisor"));
    uint256 public constant override defaultDegradationPeriod = 7 days;
    uint256 public constant override defaultFreshnessPeriod = 30 days;
    address public immutable override policyManager;
    uint256 public override lastUpdate;

    /**
     * @dev Mapping of storage subjects to their associated update timestamps.
     */
    mapping(bytes32 => uint256) public override subjectUpdates;
    
    /**
     * @dev Mapping of policy IDs to their associated mitigation parameters.
     */
    mapping(uint32 => MitigationParameters) private _mitigationParameters;

    /**
     * @dev Modifier that checks if the caller has the policy admin or supervisor role.
     * @param policyId The ID of the policy.
     */
    modifier onlyPolicyAdminOrSupervisor(uint32 policyId) {
        if (!hasRole(ROLE_SERVICE_SUPERVISOR, _msgSender())) {
            bytes32 role = bytes32(uint256(uint32(policyId)));
            if (!IPolicyManager(policyManager).hasRole(role, _msgSender())) {
                revert Unauthorized({
                    sender: _msgSender(),
                    module: "Degradable",
                    method: "_checkRole",
                    role: role,
                    reason: "sender does not have the required role",
                    context: "Degradable:onlyPolicyAdminOrSupervisor"
                });
            }
        }
        _;
    }

    /**
     * @param trustedForwarder Address of the trusted forwarder contract.
     * @param policyManager_ Address of the policy manager contract.
     * @param maximumConsentPeriod_ Maximum consent duration a user will be allowed to grant.
     */
    constructor(
        address trustedForwarder,
        address policyManager_,
        uint256 maximumConsentPeriod_
    ) Consent(trustedForwarder, maximumConsentPeriod_) {
        if (trustedForwarder == NULL_ADDRESS) revert Unacceptable({ reason: "trustedForwarder cannot be empty" });
        if (policyManager_ == NULL_ADDRESS) revert Unacceptable({ reason: "policyManager_ cannot be empty" });
        policyManager = policyManager_;
    }

    /**
     * @notice Record the timestamp of the last update to the contract.
     * @dev Must be called by derived contracts.
     * @param subject The subject to update.
     * @param time The time to record.
     */
    function _recordUpdate(address subject, uint256 time) internal {
        _recordUpdate(bytes32(uint256(uint160(subject))), time);
    }

    /**
     * @notice Record the timestamp of the last update to the contract.
     * @dev Must be called by derived contracts.
     * @param subject The subject to update.
     * @param time The time to record.
     */
    function _recordUpdate(bytes32 subject, uint256 time) internal {
        if (time > block.timestamp) revert Unacceptable({ reason: "time must be in the past" });
        if (subjectUpdates[subject] > time) revert Unacceptable({ reason: "time is older than existing update" });
        if (time > lastUpdate) lastUpdate = time;
        subjectUpdates[subject] = time;
    }

    /**
     * @dev Set the mitigation parameters for a policy.
     * @param policyId The ID of the policy.
     * @param degradationPeriod_ The time period after which the service is considered degraded.
     * @param degradationFreshness_ Used by derived service contracts to include or exclude data that was recorded
     * before the service fell into the degraded state.
     */
    function setPolicyParameters(
        uint32 policyId,
        uint256 degradationPeriod_,
        uint256 degradationFreshness_
    ) external override onlyPolicyAdminOrSupervisor(policyId) {
        if (policyId < FIRST_CONFIGURABLE_POLICY)
            revert Unacceptable({ reason: "Cannot configure genesis policies 0 and 1" });
        // acceptable range is 0 to very large
        if (degradationPeriod_ > MAX_DEGRATION_PERIOD)
            revert Unacceptable({ reason: "degradationPeriod cannot exceed 60 days" });
        if (degradationFreshness_ > MAX_DEGRATION_FRESHNESS_PERIOD)
            revert Unacceptable({ reason: "degradationFreshness cannot exceed 50 years" });
        _mitigationParameters[policyId] = MitigationParameters({
            degradationPeriod: degradationPeriod_,
            degradationFreshness: degradationFreshness_
        });
        emit SetPolicyParameters(_msgSender(), policyId, degradationPeriod_, degradationFreshness_);
    }

    /**
     * @notice Check the subjects's last recorded update and compare to policy ttl, with mitigation.
     * @dev Fallback to mitigation measures if acceptable. Use staticCall to inspect.
     * @param observer The user who must consent to reliance on degraded services.
     * @param subject The subject to inspect.
     * @param policyId PolicyId to consider for possible mitigation.
     */
    function _checkKey(address observer, address subject, uint32 policyId) internal returns (bool pass) {
        pass = _checkKey(observer, bytes32(uint256(uint160(subject))), policyId);
    }

    /**
     * @notice Check the subject's last recorded update and compare to policy ttl, with mitigation.
     * @dev Fallback to mitigation measures if acceptable. Use staticCall to inspect.
     * @param observer The user who must consent to reliance on degraded services.
     * @param subject The subject to inspect.
     * @param policyId PolicyId to consider for possible mitigation.
     */
    function _checkKey(address observer, bytes32 subject, uint32 policyId) internal returns (bool pass) {
        uint256 time = block.timestamp;
        uint256 lastSubjectUpdate = subjectUpdates[subject];

        // normal operations
        uint256 ttl = IPolicyManager(policyManager).policyTtl(policyId);
        if (time <= lastSubjectUpdate + ttl) return true;

        // check for mitigation
        pass = _canMitigate(observer, policyId, time, lastSubjectUpdate);
    }

    /**
     * @notice A Degradable service implments a compromised process.
     * @dev Must consult user Consent and Policy parameters. Must return false unless degraded.
     * Use staticCall to inspect.
     * @param observer The user who must consent to reliance on degraded services.
     * @param subject The topic to inspect.
     * @param policyId The policyId for mitigation parameters.
     */
    function canMitigate(
        address observer,
        bytes32 subject,
        uint32 policyId
    ) public view virtual override returns (bool canIndeed) {
        canIndeed = _canMitigate(observer, policyId, block.timestamp, subjectUpdates[subject]);
    }

    /**
     * @notice A Degradable service implments a compromised process.
     * @dev Must consult user Consent and Policy parameters. Must return false unless degraded.
     * @param observer The user who must consent to reliance on degraded services.
     * @param policyId The policyId for mitigation parameters.
     * @param time Derived contracts and callers provide current blocktime for comparison.
     * @param subjectUpdated Derived contracts and callers provide last subject update.
     */
    function _canMitigate(
        address observer,
        uint32 policyId,
        uint256 time,
        uint256 subjectUpdated
    ) internal view returns (bool canIndeed) {
        if (!_isDegraded(policyId, time)) return false;
        if (!_isMitigationQualified(subjectUpdated, policyId)) return false;
        if (userConsentDeadlines[observer] < time) return false;
        canIndeed = true;
    }

    /**
     * @notice A service is degraded if there has been no update for longer than the degradation period.
     * @param policyId The policyId to inspect.
     * @return isIndeed True if the service is considered degraded by the Policy.
     */
    function isDegraded(uint32 policyId) public view override returns (bool isIndeed) {
        isIndeed = _isDegraded(policyId, block.timestamp);
    }

    /**
     * @notice A service is degraded if there has been no update for longer than the degradation period.
     * @param policyId The policyId to inspect.
     * @param time Time to compare.
     * @return isIndeed True if the service is considered degraded by the Policy.
     */
    function _isDegraded(uint32 policyId, uint256 time) internal view returns (bool isIndeed) {
        if (lastUpdate == 0) return false;
        uint256 policyDegradationPeriod = _mitigationParameters[policyId].degradationPeriod;
        isIndeed = (policyDegradationPeriod == 0)
            ? time > lastUpdate + defaultDegradationPeriod
            : time > lastUpdate + policyDegradationPeriod;
    }

    /**
     * @notice Evaluate if existing services records can be used for mitigation measures.
     * @param subject Key to inspect.
     * @param policyId Policy to inspect for mitigation parameters.
     * @return qualifies True if the birthday is after the cutoff deadline for the service set by the Policy admin.
     */
    function isMitigationQualified(bytes32 subject, uint32 policyId) public view override returns (bool qualifies) {
        qualifies = _isMitigationQualified(subjectUpdates[subject], policyId);
    }

    /**
     * @notice Evaluate if existing services records can be used for mitigation measures.
     * @param lastSubjectUpdate Last recorded update for the subject.
     * @param policyId Policy to inspect for mitigation parameters.
     * @return qualifies True if the subject update time is after the mitigation cutoff  for the
     * service set by the Policy admin.
     */
    function _isMitigationQualified(uint256 lastSubjectUpdate, uint32 policyId) internal view returns (bool qualifies) {
        qualifies = lastSubjectUpdate >= mitigationCutoff(policyId);
    }

    /**
     * @notice The degradation period is maximum interval between updates before the policy considers the
     * service degraded.
     * @param policyId The policyId to inspect.
     * @return inSeconds The degradation period for the policy.
     */
    function degradationPeriod(uint32 policyId) public view override returns (uint256 inSeconds) {
        if(!IPolicyManager(policyManager).isPolicy(policyId)) revert Unacceptable({ reason: "unknown policy" });
        uint256 policyDegradationPeriod = _mitigationParameters[policyId].degradationPeriod;
        inSeconds = (policyDegradationPeriod == 0) ? defaultDegradationPeriod : policyDegradationPeriod;
    }

    /**
     * @notice A service may implement a mitigation strategy to employ while the service is degraded.
     * @dev Service mitigations can use this parameter.
     * @param policyId The policyId to inspect.
     * @return inSeconds The freshness period for the policy.
     */
    function degradationFreshness(uint32 policyId) public view override returns (uint256 inSeconds) {
        if(!IPolicyManager(policyManager).isPolicy(policyId)) revert Unacceptable({ reason: "unknown policy" });
        uint256 policyDegradationFreshness = _mitigationParameters[policyId].degradationFreshness;
        inSeconds = (policyDegradationFreshness == 0) ? defaultFreshnessPeriod : policyDegradationFreshness;
    }

    /**
     * @notice Service degradation mitigation measures depend on the oldest acceptable update.
     * @param policyId The policyId to consult for a cutoff time.
     * @return cutoffTime The oldest update that will be useable for mitigation measures.
     */
    function mitigationCutoff(uint32 policyId) public view override returns (uint256 cutoffTime) {
        uint256 _degradationFreshness = degradationFreshness(policyId);
        if (lastUpdate == 0) return block.timestamp;
        if (_degradationFreshness > lastUpdate) {
            return 0;
        } else {
            return lastUpdate - _degradationFreshness;
        }
    }
}
