// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./AddressSet.sol";
import "../interfaces/IRuleRegistry.sol";
import "../interfaces/IKeyringCredentials.sol";

/**
 @notice PolicyStorage attends to state management concerns for the PolicyManager. It establishes the
 storage layout and is responsible for internal state integrity and managing state transitions. The 
 PolicyManager is responsible for orchestration of the functions implemented here as well as access
 control. 
 */

library PolicyStorage {

    using AddressSet for AddressSet.Set;

    uint32 private constant MAX_POLICIES = 2 ** 20;
    // Approximately 2 years. Does not account for leap years.
    uint32 private constant MAX_TTL = 2 * 365 days;
    address private constant NULL_ADDRESS = address(0);

    error Unacceptable(string reason);

    /// @dev The App struct contains the essential PolicyManager state including an array of Policies. 

    struct App {
        Policy[] policies;
        AddressSet.Set globalAttestorSet;
        mapping(address => string) attestorUris;
        AddressSet.Set globalWalletCheckSet;
    }

    /// @dev PolicyScalar contains the non-indexed values in a policy configuration.

    struct PolicyScalar {
        bytes32 ruleId;
        string descriptionUtf8;
        uint32 ttl;
        uint32 gracePeriod;
        uint16 acceptRoots;
        bool allowUserWhitelists;
        bool locked;
    }

    /// @dev PolicyAttestors contains the active policy attestors as well as scheduled changes. 

    struct PolicyAttestors {
        AddressSet.Set activeSet;
        AddressSet.Set pendingAdditionSet;
        AddressSet.Set pendingRemovalSet;
    }

    /// @dev PolicyWalletChecks contains the active policy wallet checks as well as scheduled changes.

    struct PolicyWalletChecks {
        AddressSet.Set activeSet;
        AddressSet.Set pendingAdditionSet;
        AddressSet.Set pendingRemovalSet;
    }

    /**
     @dev Policy contains the active and scheduled changes and the deadline when the changes will
    take effect.
    */
    
    struct Policy {
        uint256 deadline;
        PolicyScalar scalarActive;
        PolicyScalar scalarPending;
        PolicyAttestors attestors;
        PolicyWalletChecks walletChecks;
    }

    /**
     * @notice The attestor admin can admit attestors into the global attestor whitelist. 
     * @param self PolicyManager App state.
     * @param attestor Address of the attestor's identity tree contract.
     * @param uri The URI refers to detailed information about the attestor.
     */
    function insertGlobalAttestor(
        App storage self,
        address attestor,
        string memory uri
    ) public
    {
        if(attestor == NULL_ADDRESS)
            revert Unacceptable({
                reason: "attestor cannot be empty"
            });
        if(bytes(uri).length == 0) 
            revert Unacceptable({
                reason: "uri cannot be empty"
            });        
        self.globalAttestorSet.insert(attestor, "PolicyStorage:insertGlobalAttestor");
        self.attestorUris[attestor] = uri;
    }

    /**
     * @notice The attestor admin can update the informational URIs for attestors on the whitelist.
     * @dev No onchain logic relies on the URI.
     * @param self PolicyManager App state.
     * @param attestor Address of an attestor's identity tree contract on the whitelist. 
     * @param uri The URI refers to detailed information about the attestor.
     */
    function updateGlobalAttestorUri(
        App storage self, 
        address attestor,
        string memory uri
    ) public
    {
        if(!self.globalAttestorSet.exists(attestor))
            revert Unacceptable({
                reason: "attestor not found"
            });
        if(bytes(uri).length == 0) 
            revert Unacceptable({
                reason: "uri cannot be empty"
            });  
        self.attestorUris[attestor] = uri;
    }

    /**
     * @notice The attestor admin can remove attestors from the whitelist.
     * @dev Does not remove attestors from policies that recognise the attestor to remove. 
     * @param self PolicyManager App state.
     * @param attestor Address of an attestor identity tree to remove from the whitelist. 
     */
    function removeGlobalAttestor(
        App storage self,
        address attestor
    ) public
    {
        self.globalAttestorSet.remove(attestor, "PolicyStorage:removeGlobalAttestor");
    }

    /**
     * @notice The wallet check admin can admit wallet check contracts into the system.
     * @dev Wallet checks implement the IWalletCheck interface.
     * @param self PolicyManager App state.
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function insertGlobalWalletCheck(
        App storage self,
        address walletCheck
    ) public
    {
        if(walletCheck == NULL_ADDRESS)
            revert Unacceptable({
                reason: "walletCheck cannot be empty"
            });
        self.globalWalletCheckSet.insert(walletCheck, "PolicyStorage:insertGlobalWalletCheck");
    }

    /**
     * @notice The wallet check admin can remove a wallet check from the system.
     * @dev Does not affect policies that utilize the wallet check. 
     * @param self PolicyManager App state.
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function removeGlobalWalletCheck(
        App storage self,
        address walletCheck
    ) public
    {
        self.globalWalletCheckSet.remove(walletCheck, "PolicyStorage:removeGlobalWalletCheck");
    }

    /**
     * @notice Creates a new policy that is owned by the creator.
     * @dev Maximum unique policies is 2 ^ 20.
     * @param self PolicyManager App state.
     * @param policyScalar The new policy's non-indexed values. 
     * @param attestors A list of attestor identity tree contracts.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     * @param ruleRegistry The address of the deployed RuleRegistry contract.
     * @return policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     */
    function newPolicy(
        App storage self,
        PolicyScalar calldata policyScalar,
        address[] memory attestors,
        address[] memory walletChecks,
        address ruleRegistry
    ) public returns (uint32 policyId) 
    {
        uint256 i;
        self.policies.push();
        policyId = uint32(self.policies.length - 1);
        if(policyId >= MAX_POLICIES)
            revert Unacceptable({
                reason: "max policies exceeded"
            });
        Policy storage policy = policyRawData(self, policyId);
        uint256 deadline = block.timestamp;

        writePolicyScalar(
            self,
            policyId,
            policyScalar,
            ruleRegistry,
            deadline
        );

        processStaged(self, policyId);

        for(i=0; i<attestors.length; i++) {
            address attestor = attestors[i];
            if(!self.globalAttestorSet.exists(attestor))
                revert Unacceptable({
                    reason: "attestor not found"
                });
            policy.attestors.activeSet.insert(attestor, "PolicyStorage:newPolicy");
        }

        for(i=0; i<walletChecks.length; i++) {
            address walletCheck = walletChecks[i];
            if(!self.globalWalletCheckSet.exists(walletCheck))
                revert Unacceptable({
                    reason: "walletCheck not found"
                });
            policy.walletChecks.activeSet.insert(walletCheck, "PolicyStorage:newPolicy");
        }
    }

    /**
     * @notice Returns the internal policy state without processing staged changes. 
     * @dev Staged changes with deadlines in the past are presented as pending. 
     * @param self PolicyManager App state.
     * @param policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     * @return policyInfo Policy info in the internal storage format without processing.
     */
    function policyRawData(
        App storage self, 
        uint32 policyId
    ) public view returns (Policy storage policyInfo) 
    {
        policyInfo = self.policies[policyId];
    }

    /**
     * @notice Updates policy storage if the deadline is in the past.
     * @dev Always call this before inspecting the the active policy state. .
     * @param self A Policy object.
     */
    function processStaged(
        App storage self,
        uint32 policyId
    ) public
    {
        Policy storage policy = self.policies[policyId];
        uint256 deadline = policy.deadline;

        uint256 count = policy.attestors.pendingAdditionSet.count();
        if(deadline > 0 && deadline <= block.timestamp) {
            policy.scalarActive = policy.scalarPending;
            while(count > 0) {
                address attestor = policy.attestors.pendingAdditionSet.keyAtIndex(
                    policy.attestors.pendingAdditionSet.count() - 1
                );
                policy.attestors.activeSet.insert(
                    attestor,
                    "policyStorage:processStaged"
                );
                policy.attestors.pendingAdditionSet.remove(
                    attestor,
                    "policyStorage:processStaged"
                );
                count--;
            }
            
            count = policy.attestors.pendingRemovalSet.count();
            while(count > 0) {
                address attestor = policy.attestors.pendingRemovalSet.keyAtIndex(
                    policy.attestors.pendingRemovalSet.count() - 1
                );
                policy.attestors.activeSet.remove(
                    attestor,
                    "policyStorage:processStaged"
                );
                policy.attestors.pendingRemovalSet.remove(
                    attestor,
                    "policyStorage:processStaged"
                );
                count--;
            }

            count = policy.walletChecks.pendingAdditionSet.count();
            while(count > 0) {
                address walletCheck = policy.walletChecks.pendingAdditionSet.keyAtIndex(
                    policy.walletChecks.pendingAdditionSet.count() - 1
                );
                policy.walletChecks.activeSet.insert(
                    walletCheck,
                    "policyStorage:processStaged"
                );
                policy.walletChecks.pendingAdditionSet.remove(
                    walletCheck,
                    "policyStorage:processStaged"
                );
                count--;
            }

            count = policy.walletChecks.pendingRemovalSet.count();
            while(count > 0) {
                address walletCheck = policy.walletChecks.pendingRemovalSet.keyAtIndex(
                    policy.walletChecks.pendingRemovalSet.count() - 1
                );
                policy.walletChecks.activeSet.remove(
                    walletCheck,
                    "policyStorage:processStaged"
                );
                policy.walletChecks.pendingRemovalSet.remove(
                    walletCheck,
                    "policyStorage:processStaged"
                );
                count--;
            }
            policy.deadline = 0;
        }
    }

    /**
     * @notice Enforces policy locks. 
     * @dev Reverts if the active policy lock is set to true.
     * @param policy A Policy object.
     */
    function checkLock(
        Policy storage policy
    ) public view 
    {
        if(isLocked(policy))
            revert Unacceptable({
                reason: "policy is locked"
            });
    }

    /**
     * @notice Inspect the active policy lock.
     * @param policy A Policy object.
     * @return isIndeed True if the active policy locked parameter is set to true. True value if PolicyStorage
     is locked, otherwise False.
     */
    function isLocked(Policy storage policy) public view returns(bool isIndeed) {
        isIndeed = policy.scalarActive.locked;
    }

    /**
     * @notice Processes staged changes if the current deadline has passed and updates the deadline. 
     * @dev The deadline must be at least as far in the future as the active policy gracePeriod. 
     * @param self A Policy object.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function setDeadline(
        App storage self,
        uint32 policyId, 
        uint256 deadline
    ) public
    {
        Policy storage policy = self.policies[policyId];
        checkLock(policy);

        // Deadline of 0 allows staging of changes with no implementation schedule.
        // Positive deadlines must be at least graceTime seconds in the future.
     
        if(deadline != 0 && 
            (deadline < block.timestamp + policy.scalarActive.gracePeriod)
        )
            revert Unacceptable({
                reason: "deadline in the past or too soon"
        });
        policy.deadline = deadline;
    }

    /**
     * @notice Non-indexed Policy values can be updated in one step. 
     * @param self PolicyManager App state.
     * @param policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     * @param policyScalar The new non-indexed properties. 
     * @param ruleRegistry The address of the deployed RuleRegistry contract. 
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function writePolicyScalar(
        App storage self,
        uint32 policyId,
        PolicyStorage.PolicyScalar calldata policyScalar,
        address ruleRegistry,
        uint256 deadline
    ) public {
        PolicyStorage.Policy storage policyObj = policyRawData(self, policyId);
        processStaged(self, policyId);
        writeRuleId(policyObj, policyScalar.ruleId, ruleRegistry);
        writeDescription(policyObj, policyScalar.descriptionUtf8);
        writeTtl(policyObj, policyScalar.ttl);
        writeGracePeriod(policyObj, policyScalar.gracePeriod);
        writeAcceptRoots(policyObj, policyScalar.acceptRoots);
        writeAllowUserWhitelists(policyObj, policyScalar.allowUserWhitelists);
        writePolicyLock(policyObj, policyScalar.locked);
        setDeadline(self, policyId, deadline);
    }

    /**
     * @notice Writes a new RuleId to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param ruleId The unique identifier of a Rule.
     * @param ruleRegistry The address of the deployed RuleRegistry contract. 
     */
    function writeRuleId(
        Policy storage self, 
        bytes32 ruleId, 
        address ruleRegistry
    ) public
    {
        if(!IRuleRegistry(ruleRegistry).isRule(ruleId))
            revert Unacceptable({
                reason: "rule not found"
            });
        self.scalarPending.ruleId = ruleId;
    }

    /**
     * @notice Writes a new descriptionUtf8 to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param descriptionUtf8 Policy description in UTF-8 format. 
     */
    function writeDescription(
        Policy storage self, 
        string memory descriptionUtf8
    ) public
    {
        if(bytes(descriptionUtf8).length == 0) 
            revert Unacceptable({
                reason: "descriptionUtf8 cannot be empty"
            });
        self.scalarPending.descriptionUtf8 = descriptionUtf8;
    }

    /**
     * @notice Writes a new ttl to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param ttl The maximum acceptable credential age in seconds.
     */
    function writeTtl(
        Policy storage self,
        uint32 ttl
    ) public
    {
        if(ttl > MAX_TTL) 
            revert Unacceptable({ reason: "ttl exceeds maximum duration" });
        self.scalarPending.ttl = ttl;
    }

    /**
     * @notice Writes a new gracePeriod to the pending Policy changes in a Policy. 
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param self A Policy object.
     * @param gracePeriod The minimum acceptable deadline.
     */
    function writeGracePeriod(
        Policy storage self,
        uint32 gracePeriod
    ) public
    {
        // 0 is acceptable
        self.scalarPending.gracePeriod = gracePeriod;
    }

    /**
     * @notice Writes a new allowUserWhitelists state in the pending Policy changes in a Policy. 
     * @param self A Policy object.
     * @param allowUserWhitelists True if whitelists are allowed, otherwise false.
     */
    function writeAllowUserWhitelists(
        Policy storage self,
        bool allowUserWhitelists
    ) public
    {
        self.scalarPending.allowUserWhitelists = allowUserWhitelists;
    }

    /**
     * @notice Writes a new locked state in the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param setPolicyLocked True if the policy is to be locked, otherwise false.
     */
    function writePolicyLock(
        Policy storage self,
        bool setPolicyLocked
    ) public
    {
        self.scalarPending.locked = setPolicyLocked;
    }

    /**
     * @notice Writes a new value for acceptRoots in the pending Policy changes of a Policy. 
     * @dev The KeyringZkUpdater will accept the n most recent roots, where n is specified here. 
     * @param self A Policy object.
     * @param acceptRoots The depth of most recent roots to always accept.
     */
    function writeAcceptRoots(
        Policy storage self,
        uint16 acceptRoots
    ) public
    {
        self.scalarPending.acceptRoots = acceptRoots;
    }

    /**
     * @notice Writes attestors to pending Policy attestor additions. 
     * @param self PolicyManager App state.
     * @param policy A Policy object.
     * @param attestors The address of one or more Attestors to add to the Policy.
     */
    function writeAttestorAdditions(
        App storage self,
        Policy storage policy,
        address[] calldata attestors
    ) public
    {
        for(uint i = 0; i < attestors.length; i++) {
            _writeAttestorAddition(self, policy, attestors[i]);
        }        
    }

    /**
     * @notice Writes an attestor to pending Policy attestor additions. 
     * @dev If the attestor is scheduled to be remove, unschedules the removal. 
     * @param self PolicyManager App state.
     * @param policy A Policy object. 
     * @param attestor The address of an Attestor to add to the Policy.
     */
    function _writeAttestorAddition(
        App storage self,
        Policy storage policy,
        address attestor
    ) private
    {
        if(!self.globalAttestorSet.exists(attestor))
            revert Unacceptable({
                reason: "attestor not found"
            });
        if(policy.attestors.pendingRemovalSet.exists(attestor)) {
            policy.attestors.pendingRemovalSet.remove(attestor, "PolicyStorage:_writeAttestorAddition");
        } else {
            if(policy.attestors.activeSet.exists(attestor)) {
                revert Unacceptable({
                    reason: "attestor already in policy"
                });
            }
            policy.attestors.pendingAdditionSet.insert(attestor, "PolicyStorage:_writeAttestorAddition");
        }
    }

    /**
     * @notice Writes attestors to pending Policy attestor removals. 
     * @param self A Policy object.
     * @param attestors The address of one or more Attestors to remove from the Policy.
     */
    function writeAttestorRemovals(
        Policy storage self,
        address[] calldata attestors
    ) public
    {
        for(uint i = 0; i < attestors.length; i++) {
            _writeAttestorRemoval(self, attestors[i]);
        }
    }

    /**
     * @notice Writes an attestor to a Policy's pending attestor removals. 
     * @dev Cancels the addition if the attestor is scheduled to be added. 
     * @param self PolicyManager App state.
     * @param attestor The address of a Attestor to remove from the Policy.
     */
    function _writeAttestorRemoval(
        Policy storage self,
        address attestor
    ) private
    {
        if(self.attestors.pendingAdditionSet.exists(attestor)) {
            self.attestors.pendingAdditionSet.remove(attestor, "PolicyStorage:_writeAttestorRemoval");
        } else {
            if(!self.attestors.activeSet.exists(attestor)) {
                revert Unacceptable({
                    reason: "attestor not found"
                });
            }
            self.attestors.pendingRemovalSet.insert(attestor, "PolicyStorage:_writeAttestorRemoval");
        }
    }

    /**
     * @notice Writes wallet checks to a Policy's pending wallet check additions.
     * @param self PolicyManager App state.
     * @param policy A PolicyStorage object.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     */
    function writeWalletCheckAdditions(
        App storage self,
        Policy storage policy,
        address[] memory walletChecks
    ) public
    {
        for(uint i = 0; i < walletChecks.length; i++) {
            _writeWalletCheckAddition(self, policy, walletChecks[i]);
        }
    }

    /**
     * @notice Writes a wallet check to a Policy's pending wallet check additions. 
     * @dev Cancels removal if the wallet check is scheduled for removal. 
     * @param self PolicyManager App state.
     * @param policy A Policy object. 
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function _writeWalletCheckAddition(
        App storage self,
        Policy storage policy,
        address walletCheck
    ) private
    {
        if(!self.globalWalletCheckSet.exists(walletCheck))
            revert Unacceptable({
                reason: "walletCheck not found"
            });
        if(policy.walletChecks.pendingRemovalSet.exists(walletCheck)) {
            policy.walletChecks.pendingRemovalSet.remove(walletCheck, "PolicyStorage:_writeWalletCheckAddition");
        } else {
            if(policy.walletChecks.activeSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck already in policy"
                });
            }
            if(policy.walletChecks.pendingAdditionSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck addition already scheduled"
                });
            }
        }
        policy.walletChecks.pendingAdditionSet.insert(walletCheck, "PolicyStorage:_writeWalletCheckAddition");
    }

    /**
     * @notice Writes wallet checks to a Policy's pending wallet check removals. 
     * @param self A Policy object.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     */
    function writeWalletCheckRemovals(
        Policy storage self,
        address[] memory walletChecks
    ) public
    {
        for(uint i = 0; i < walletChecks.length; i++) {
            _writeWalletCheckRemoval(self, walletChecks[i]);
        }
    }

    /**
     * @notice Writes a wallet check to a Policy's pending wallet check removals. 
     * @dev Unschedules addition if the wallet check is present in the Policy's pending wallet check additions. 
     * @param self A Policy object.
     * @param walletCheck The address of a Wallet Check to remove from the Policy. 
     */
    function _writeWalletCheckRemoval(
        Policy storage self,
        address walletCheck
    ) private
    {
        if(self.walletChecks.pendingAdditionSet.exists(walletCheck)) {
            self.walletChecks.pendingAdditionSet.remove(walletCheck, "PolicyStorage:_writeWalletCheckRemoval");
        } else {
            if(!self.walletChecks.activeSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck is not in policy"
                });
            }
            if(self.walletChecks.pendingRemovalSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck removal already scheduled"
                });
            }
        }
        self.walletChecks.pendingRemovalSet.insert(walletCheck, "PolicyStorage:_writeWalletCheckRemoval");
    }
}
