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

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMonadexCampaignsFactory } from "./interfaces/IMonadexCampaignsFactory.sol";
import { IMonadexCampaignsPool } from "./interfaces/IMonadexCampaignsPool.sol";

contract MonadexCampaignsRouter {
    using SafeERC20 for IERC20;

    address private immutable i_factory;

    error MonadexCampaignsRouter__DeadlinePassed();

    modifier beforeDeadline(uint256 _deadline) {
        if (block.timestamp > _deadline) revert MonadexCampaignsRouter__DeadlinePassed();
        _;
    }

    constructor(address _factory) {
        i_factory = _factory;
    }

    function purchaseExactSaleTokensForFundingTokensInStage1(
        address _saleToken,
        address _fundingToken,
        uint256 _maxFundingTokenAmount,
        uint256 _deadline
    )
        external
        beforeDeadline(_deadline)
        returns (uint256)
    { }

    function purchaseSaleTokensForExactFundingTokensInStage1(
        address _saleToken,
        address _fundingToken,
        uint256 _minSaleTokenAmount,
        uint256 _deadline
    )
        external
        beforeDeadline(_deadline)
        returns (uint256)
    { }

    function purchaseSaleTokensInStage2(
        address _saleToken,
        address _fundingToken,
        uint256 _saleTokenAmount
    )
        external
        returns (uint256)
    { }
}
