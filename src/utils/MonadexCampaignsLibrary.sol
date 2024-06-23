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

import { Math } from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IMonadexCampaignsPool } from "../interfaces/IMonadexCampaignsPool.sol";

import { MonadexCampaignsTypes } from "./MonadexCampaignsTypes.sol";

library MonadexCampaignsLibrary {
    function amountToPurchaseInStage1(
        uint256 _saleTokenReserves,
        uint256 _fundingTokenReserves,
        uint256 _fundingTokenAmount
    )
        internal
        pure
        returns (uint256)
    {
        return Math.mulDiv(
            _saleTokenReserves, _fundingTokenAmount, _fundingTokenReserves + _fundingTokenAmount
        );
    }

    function getFundingTokenAmountforSaleTokenAmountInStage1(
        address _pool,
        uint256 _saleTokenAmount
    )
        internal
        view
        returns (uint256)
    {
        (uint256 saleTokenReserves, uint256 fundingTokenReserves) =
            IMonadexCampaignsPool(_pool).getReserves();

        return Math.mulDiv(
            _saleTokenAmount, fundingTokenReserves, saleTokenReserves - _saleTokenAmount
        );
    }

    function amountToPurchaseInStage2(
        uint256 _fundingTokenAmount,
        MonadexCampaignsTypes.PriceThreshold memory _price
    )
        internal
        pure
        returns (uint256)
    {
        return Math.mulDiv(_price.saleTokenAmount, _fundingTokenAmount, _price.fundingTokenAmount);
    }

    function getFundingTokenAmountforSaleTokenAmountInStage2(
        address _pool,
        uint256 _saleTokenAmount
    )
        internal
        view
        returns (uint256)
    {
        MonadexCampaignsTypes.PriceThreshold memory price =
            IMonadexCampaignsPool(_pool).getPriceThreshold();

        return Math.mulDiv(price.fundingTokenAmount, _saleTokenAmount, price.saleTokenAmount);
    }
}
