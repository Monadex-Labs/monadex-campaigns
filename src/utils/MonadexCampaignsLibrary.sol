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

library MonadexCampaignsLibrary {
    function amountToPurchaseInStage1(
        uint256 _saleTokenReserves,
        uint256 _fundingTokenReserves,
        uint256 _fundingTokenAmount
    )
        internal
    {
        return (_saleTokenReserves * _fundingTokenAmount)
            / (_fundingTokenReserves + _fundingTokenAmount);
    }
}
