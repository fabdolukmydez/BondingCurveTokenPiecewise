// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MinimalERC20.sol";

/// @title BondingCurveTokenPiecewise
/// @notice Piecewise bonding curve with tiers.
contract BondingCurveTokenPiecewise is MinimalERC20 {
    struct Tier { uint256 limit; uint256 pricePerToken; }
    Tier[] public tiers;
    address public owner;
    event Bought(address indexed buyer, uint256 tokens, uint256 cost);

    constructor() MinimalERC20("BondingPiece", "BCP") {
        owner = msg.sender;
        // example tiers (limits in whole tokens)
        tiers.push(Tier({limit: 1000, pricePerToken: 1e14}));
        tiers.push(Tier({limit: 5000, pricePerToken: 2e14}));
        tiers.push(Tier({limit: type(uint256).max, pricePerToken: 5e14}));
    }

    function currentTier(uint256 supply) public view returns (uint256 idx) {
        uint256 accum = 0;
        for(uint256 i=0;i<tiers.length;i++) {
            accum += tiers[i].limit;
            if(supply < accum) return i;
        }
        return tiers.length - 1;
    }

    function priceToMint(uint256 n) public view returns (uint256) {
        uint256 cost = 0;
        uint256 S = totalSupply;
        for(uint256 i=0;i<n;i++) {
            uint256 idx = currentTier(S + i);
            cost += tiers[idx].pricePerToken;
        }
        return cost;
    }

    function buy(uint256 n) external payable {
        uint256 cost = priceToMint(n);
        require(msg.value >= cost, "insufficient");
        _mint(msg.sender, n * (10 ** decimals));
        if(msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
        emit Bought(msg.sender, n, cost);
    }

    receive() external payable {}
}
