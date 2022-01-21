// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IArtist.sol";

contract Raffle is Ownable {
  IArtist nftContract;
  uint drawMinimum;
  uint entryCount = 0;
  uint entryMinimum;
  bool isDrawn;
  uint whiteListMaximum;

  mapping (uint => address) public participants;
  mapping (uint => address) public whiteList;

  constructor(
    address _nftContract,
    uint _drawMinimum,
    uint _entryMinimum,
    uint _whiteListMaximum
  ) {
    initialize(_nftContract, _drawMinimum, _entryMinimum, _whiteListMaximum);
    isDrawn = false;
  }

  function initialize(
    address _nftContract,
    uint _drawMinimum,
    uint _entryMinimum,
    uint _whiteListMaximum
  ) 
  public onlyOwner 
  {
    nftContract = IArtist(_nftContract);
    drawMinimum = _drawMinimum;
    entryMinimum = _entryMinimum;
    whiteListMaximum = _whiteListMaximum;
  }

  function draw() external onlyOwner {
    require(!isDrawn, "This raffle has already been drawn");

    uint count = whiteListMaximum;
    if (count > entryCount) {
      count = entryCount;
    }

    uint y = 0;
    for (uint x = 0; x < count; x++) {
      if (participants[x].balance >= drawMinimum) {
        whiteList[y] = participants[x];
        y++;
      }
    }
    
    address[] memory wl = new address[](y);
    for (uint x = 0; x < y; x++) {
      wl[x] = whiteList[x];
    }

    nftContract.addMinter(wl);

    isDrawn = true;
  }

  function enter() external 
  {
    require(msg.sender.balance >= entryMinimum, "Your balance does not meet the minimum entry requirement");
    participants[entryCount] = msg.sender;
    entryCount++;
  }
}
