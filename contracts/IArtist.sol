// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IArtist {

  struct Person {
    uint8 background;
    uint8 body;
    uint8 eyes;
    uint8 teeth;
    uint8 garment;
    uint8 chain;
    uint8 face;
    uint8 ear;
    uint8 head;
  }

  function addMinter(address[] memory _minters) external;
  function getTokenTraits(uint256 tokenId) external view returns (Person memory);
}
