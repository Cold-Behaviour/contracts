// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ILayers {
    function getTokenUri(uint256 tokenId) external view returns (string memory);
}