// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ITornadoInstance.sol";
import "./PGRouter.sol";

contract InstanceRegistry {
    using SafeERC20 for IERC20;

    enum InstanceState {
        DISABLED,
        ENABLED,
        DEPOSIT_DISABLED,
        WITHDRAW_DISABLED
    }

    struct Instance {
        bool isERC20;
        IERC20 token;
        InstanceState state;
        // the fee of the uniswap pool which will be used to get a TWAP
        uint24 uniswapPoolSwappingFee;
        // the fee the protocol takes from relayer, it should be multiplied by PROTOCOL_FEE_DIVIDER from FeeManager.sol
        uint32 protocolFeePercentage;
        uint256 maxDepositAmount;
    }

    struct TornadoConfig {
        ITornadoInstance addr;
        Instance instance;
    }

    address public immutable governance;
    PGRouter public router;

    mapping(ITornadoInstance => Instance) public instances;
    ITornadoInstance[] public instanceIds;

    event InstanceStateUpdated(
        ITornadoInstance indexed instance,
        InstanceState state
    );
    event RouterRegistered(address pgRouter);

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not authorized");
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }

    /**
     * @dev initialise a set of tornado instances.
     */
    function initInstances(TornadoConfig[] memory _instances) external onlyGovernance {
        for (uint256 i = 0; i < _instances.length; i++) {
            _updateInstance(_instances[i]);
            instanceIds.push(_instances[i].addr);
        }
    }

    /**
     * @dev Add or update an instance.
     */
    function updateInstanceState(ITornadoInstance _addr, InstanceState _state) external virtual onlyGovernance {
        Instance storage _instance = instances[_addr];
        _instance.state = _state;
        emit InstanceStateUpdated(_addr, _state);
    }

    /**
     * @dev Add or update an instance.
     */
    function updateInstance(
        TornadoConfig calldata _tornadoConf
    ) external virtual onlyGovernance {
        require(
            _tornadoConf.instance.state != InstanceState.DISABLED,
            "Use removeInstance() for remove"
        );
        if (instances[_tornadoConf.addr].state == InstanceState.DISABLED) {
            instanceIds.push(_tornadoConf.addr);
        }
        _updateInstance(_tornadoConf);
    }

    /**
     * @dev Remove an instance.
     * @param _instanceId The instance id in `instanceIds` mapping to remove.
     */
    function removeInstance(
        uint256 _instanceId
    ) external virtual onlyGovernance {
        ITornadoInstance _instance = instanceIds[_instanceId];
        (bool isERC20, IERC20 token) = (
            instances[_instance].isERC20,
            instances[_instance].token
        );

        if (isERC20) {
            uint256 allowance = token.allowance(
                address(router),
                address(_instance)
            );
            if (allowance != 0) {
                router.approveExactToken(token, address(_instance), 0);
            }
        }

        delete instances[_instance];
        instanceIds[_instanceId] = instanceIds[instanceIds.length - 1];
        instanceIds.pop();
        emit InstanceStateUpdated(_instance, InstanceState.DISABLED);
    }

    /**
     * @notice This function should allow governance to set a new protocol fee for relayers
     * @param instance the to update
     * @param newFee the new fee to use
     * */
    function setProtocolFee(
        ITornadoInstance instance,
        uint32 newFee
    ) external onlyGovernance {
        instances[instance].protocolFeePercentage = newFee;
    }

    /**
     * @notice This function should allow governance to set a new tornado proxy address
     * @param routerAddress address of the new proxy
     * */
    function setPGRouter(address routerAddress) external onlyGovernance {
        router = PGRouter(routerAddress);
        emit RouterRegistered(routerAddress);
    }

    function _updateInstance(TornadoConfig memory _tornadoConf) internal virtual {
        instances[_tornadoConf.addr] = _tornadoConf.instance;

        if (_tornadoConf.instance.isERC20) {
            IERC20 token = IERC20(_tornadoConf.addr.token());
            require(token == _tornadoConf.instance.token, "Incorrect token");
            uint256 allowance = token.allowance(
                address(router),
                address(_tornadoConf.addr)
            );

            if (allowance == 0) {
                router.approveExactToken(
                    token,
                    address(_tornadoConf.addr),
                    type(uint256).max
                );
            }
        }
        emit InstanceStateUpdated(_tornadoConf.addr, _tornadoConf.instance.state);
    }

    /**
     * @dev Returns all instance configs
     */
    function getAllInstances() public view returns (TornadoConfig[] memory result) {
        result = new TornadoConfig[](instanceIds.length);
        for (uint256 i = 0; i < instanceIds.length; i++) {
            ITornadoInstance _instance = instanceIds[i];
            result[i] = TornadoConfig({
                addr: _instance,
                instance: instances[_instance]
            });
        }
    }

    /**
     * @dev Returns all instance addresses
     */
    function getAllInstanceAddresses()
        public
        view
        returns (ITornadoInstance[] memory result)
    {
        result = new ITornadoInstance[](instanceIds.length);
        for (uint256 i = 0; i < instanceIds.length; i++) {
            result[i] = instanceIds[i];
        }
    }

    /// @notice get erc20 tornado instance token
    /// @param instance the interface (contract) key to the instance data
    function getPoolToken(
        ITornadoInstance instance
    ) external view returns (address) {
        return address(instances[instance].token);
    }
}