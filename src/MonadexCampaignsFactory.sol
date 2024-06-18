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

import { IMonadexCampaignsFactory } from "./interfaces/IMonadexCampaigns.sol";

import { MonadexCampaignsPool } from "./MonadexCampaignsPool.sol";
import { MonadexCampaignsTypes } from "./utils/MonadexCampaignsTypes.sol";

contract MonadexCampaignsFactory is Ownable2Step, IMonadexCampaignsFactory {
    mapping(address saleToken => mapping(address fundingToken => address pool)) private
        s_tokenToPool;
    mapping(address pool => address team) private s_poolToTeam;

    event CampaignPoolDeployed(
        address indexed pool, MonadexCampaignsTypes.CreateCampaign indexed campaign
    );

    error MonadexCampaignsFactory__CampaignConfigError();

    constructor() Ownable(msg.sender) { }

    function createCampaign(MonadexCampaignsTypes.CreateCampaign calldata _campaignParams)
        external
        onlyOwner
        returns (address)
    {
        if (
            _campaignParams.team == adress(0) || _campaignParams.saleToken == address(0)
                || _campaignParams.fundingToken == address(0)
                || _campaignParams.saleToken == _campaignParams.fundingToken
                || _campaignParams.saleToken == 0 || _campaignParams.fundingTokenVirtualAmount == 0
                || _campaignParams.priceThreshold > _campaignParams.saleTokenAmount
                || _campaignParams.endingTimestamp < block.timestamp
        ) revert MonadexCampaignsFactory__CampaignConfigError();

        MonadexCampaignsPool pool = new MonadexCampaignsPool(_campaignParams, owner());
        s_tokenToPool[_campaignParams.saleToken][_campaignParams.fundingToken] = address(pool);
        s_tokenToTeam[address(pool)] = _campaignParams.team;

        IERC20(_campaignParams.saleToken).safeTransferFrom(
            owner(), address(pool), _campaignParams.saleTokenAmount
        );

        emit CampaignPoolDeployed(address(pool), _campaignParams);

        return address(pool);
    }

    function getPool(address _saleToken, address _fundingToken) external view returns (address) {
        return s_tokenToPool[_saleToken][_fundingToken];
    }

    function getTeam(address _pool) external view returns (address) {
        return s_poolToTeam[_pool];
    }
}
