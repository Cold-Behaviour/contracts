// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INft {
    
  //functions
  function getTokenData(uint256 tokenId) external view returns (uint[] memory);
  function addMinter(address[] memory _minters) external;
}