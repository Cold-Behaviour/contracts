// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./INft.sol";

contract Raffle is Ownable {
  INft nftContract;
  uint drawMinimum;
  uint entryCount = 0;
  uint entryMinimum;
  bool isDrawn;
  uint whiteListMaximum;

  mapping (uint => address) public participants;
  mapping (uint => address) public whiteList;

  event Entered(address _participant, uint _entryCount);
  event Drawn();

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
    nftContract = INft(_nftContract);
    drawMinimum = _drawMinimum;
    entryMinimum = _entryMinimum;
    whiteListMaximum = _whiteListMaximum;
  }

  function draw() external onlyOwner {
    require(!isDrawn, "This raffle has already been drawn");

    uint count = whiteListMaximum;
    uint interval = 1;
    if (count > entryCount) {
      count = entryCount;
    } else {
      interval = entryCount / count;
    }

    uint y = 0;
    for (uint x = 0; x < count; x += interval) {
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

    emit Drawn();
  }

  function enter() external 
  {
    require(msg.sender.balance >= entryMinimum, "Your balance does not meet the minimum entry requirement");
    bool exists = false;
    for (uint x = 0; x < entryCount; x++) {
      if (participants[x] == msg.sender) {
        exists = true;
      }
    }
    require(!exists, "You have already entered the raffle");

    participants[entryCount] = msg.sender;
    entryCount++;

    emit Entered(msg.sender, entryCount);
  }
}
