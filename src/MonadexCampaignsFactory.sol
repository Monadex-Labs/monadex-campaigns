// Layout:
//     - pragma
//     - imports
//     - interfaces, libraries, contracts
//     - type declarations
//     - state variables
//     - events
//     - errors
//     - modifiers
//     - functions
//         - constructor
//         - receive function (if exists)
//         - fallback function (if exists)
//         - external
//         - public
//         - internal
//         - private

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Ownable, Ownable2Step } from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMonadexCampaignsFactory } from "./interfaces/IMonadexCampaignsFactory.sol";

import { MonadexCampaignsPool } from "./MonadexCampaignsPool.sol";
import { MonadexCampaignsTypes } from "./utils/MonadexCampaignsTypes.sol";

contract MonadexCampaignsFactory is Ownable2Step, IMonadexCampaignsFactory {
    using SafeERC20 for IERC20;

    mapping(address saleToken => mapping(address fundingToken => address pool)) private
        s_tokensToPool;
    mapping(address pool => address team) private s_poolToTeam;

    MonadexCampaignsTypes.Fee private s_protocolFee;

    event CampaignPoolDeployed(
        address indexed pool, MonadexCampaignsTypes.CreateCampaign indexed campaign
    );

    error MonadexCampaignsFactory__CampaignConfigError();

    constructor(MonadexCampaignsTypes.Fee memory _protocolFee) Ownable(msg.sender) {
        s_protocolFee = _protocolFee;
    }

    function createCampaign(MonadexCampaignsTypes.CreateCampaign calldata _campaignParams)
        external
        onlyOwner
        returns (address)
    {
        if (
            _campaignParams.team == address(0) || _campaignParams.saleTokenSupplier == address(0)
                || _campaignParams.saleToken == address(0) || _campaignParams.fundingToken == address(0)
                || _campaignParams.saleToken == _campaignParams.fundingToken
                || _campaignParams.saleTokenAmount == 0
                || _campaignParams.fundingTokenVirtualAmount == 0
                || _campaignParams.priceThreshold.saleTokenAmount > _campaignParams.saleTokenAmount
                || _campaignParams.priceThreshold.fundingTokenAmount
                    < _campaignParams.fundingTokenVirtualAmount
                || _campaignParams.endingTimestamp < block.timestamp
                || _campaignParams.vestingCliff == 0
        ) revert MonadexCampaignsFactory__CampaignConfigError();

        MonadexCampaignsPool pool = new MonadexCampaignsPool(_campaignParams);
        s_tokensToPool[_campaignParams.saleToken][_campaignParams.fundingToken] = address(pool);
        s_poolToTeam[address(pool)] = _campaignParams.team;

        IERC20(_campaignParams.saleToken).safeTransferFrom(
            _campaignParams.saleTokenSupplier, address(pool), _campaignParams.saleTokenAmount
        );

        emit CampaignPoolDeployed(address(pool), _campaignParams);

        return address(pool);
    }

    function getPool(address _saleToken, address _fundingToken) external view returns (address) {
        return s_tokensToPool[_saleToken][_fundingToken];
    }

    function getTeam(address _pool) external view returns (address) {
        return s_poolToTeam[_pool];
    }

    function getProtocolFee() external view returns (MonadexCampaignsTypes.Fee memory) {
        return s_protocolFee;
    }
}
