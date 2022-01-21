// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IArtist {

  struct Person {
    uint8 background;
    uint8 skin;
    uint8 neck;
    uint8 head;
    uint8 mouth;
    uint8 beard;
    uint8 eyes;
    uint8 clothes;
    uint8 earrings;
    uint8 glasses;
  }

  function addMinter(address[] memory _minters) external;
  function getTokenTraits(uint256 tokenId) external view returns (Person memory);
}
