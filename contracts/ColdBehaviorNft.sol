// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./INft.sol";
import "./ILayers.sol";

contract ColdBehaviorNft is INft, ERC721, AccessControl {
  //Constants
  uint public constant MAX_TOKENS = 8888;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

  //State Variables
  uint8[][][] public allowedCombinations;  //uint8[layer][option][path_to_item_indexes_in_next_level]
  
  ILayers public layersContract;
  uint8 public maxMintPerAddress;
  uint public minted = 0;
  bool public mintingStarted;
  uint public mintPrice;
  address public teamAddress;

  //State Mappings
  mapping (uint256 => INft.Person) public tokenData; // token Id => Person
  
  //Events

  //Constructor
  constructor(address _team, address _layersContract) ERC721("Artist", "CBA") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(WHITELIST_ROLE, msg.sender);

    layersContract = ILayers(_layersContract);
    mintPrice = 0.01 ether; //for testing, change for production
    maxMintPerAddress = 2;
    mintingStarted = false;

    teamAddress = _team;
  }

  //Functions
  function addMinter(address[] memory _minters) external onlyRole(WHITELIST_ROLE) {
    for (uint x = 0; x < _minters.length; x++) {
      _grantRole(MINTER_ROLE, _minters[x]);
    }
  }

  function generate(uint256 tokenId, uint256 rand) internal returns (Person memory t) {
    t = selectOptions(rand);
    bool exists = false;
    for (uint x = 0; x < tokenId; x++) {
      if (structToHash(tokenData[x]) == structToHash(t)) {
        exists = true;
        break;
      }
    }

    if (!exists) {
      tokenData[tokenId] = t;
      return t;
    }

    return generate(tokenId, random(rand));
  }

  function getTokenData(uint256 tokenId) external override view returns (Person memory) {
    return tokenData[tokenId];
  }

  function mint(uint8 amount) external payable onlyRole(MINTER_ROLE) {
    require(mintingStarted, "Minting has not yet started");
    require(msg.value >= (mintPrice * amount), "The amount specified does not match the minimum mint price");
    require(balanceOf(msg.sender) < maxMintPerAddress, "You may not mint any more tokens with this address");
    require(minted + amount <= MAX_TOKENS, "All tokens have been minted");
    
    (bool success, ) = teamAddress.call{value: (mintPrice * amount)}("");
    require(success, "Contract execution Failed");

    for (uint8 i = 0; i < amount; i++) {
      minted++;
      uint rand = random(minted);
      generate(minted, rand);
      _safeMint(msg.sender, minted);
    }
  }

  function mintToggle() external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintingStarted = !mintingStarted;
  }

  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
    tx.origin,
    blockhash(block.number - 1),
    block.timestamp,
    seed
    )));
  }

  function selectOption(uint8 rand, uint8 layer, uint8 previousLevelIndex) internal view returns (uint8 option) {
    if (layer == 0) {
      option = uint8(rand) % uint8(allowedCombinations[layer].length);
    } else {
      option = uint8(rand) % uint8(allowedCombinations[layer - 1][previousLevelIndex].length);
    }
    
    return option;
  }

  function selectOptions(uint256 rand) internal view returns (Person memory t) {
    rand >>= 16;
    t.background = selectOption(uint8(rand & 0xFFFF), 0, 0);  
    rand >>= 16;
    t.body = selectOption(uint8(rand & 0xFFFF), 1, t.background);
    rand >>= 16;
    t.eyes = selectOption(uint8(rand & 0xFFFF), 2, t.body);
    rand >>= 16;
    t.teeth = selectOption(uint8(rand & 0xFFFF), 3, t.eyes);
    rand >>= 16;
    t.garment = selectOption(uint8(rand & 0xFFFF), 4, t.teeth);
    rand >>= 16;
    t.chain = selectOption(uint8(rand & 0xFFFF), 5, t.garment);
    rand >>= 16;
    t.face = selectOption(uint8(rand & 0xFFFF), 6, t.chain);
    rand >>= 16;
    t.ear = selectOption(uint8(rand & 0xFFFF), 7, t.face);
    rand >>= 16;
    t.head = selectOption(uint8(rand & 0xFFFF), 8, t.ear);
  }

  function structToHash(Person memory s) internal pure returns (uint256) {
    return uint256(bytes32(
    abi.encodePacked(
        s.background,
        s.body,
        s.eyes,
        s.teeth,
        s.garment,
        s.chain,
        s.face,
        s.ear,
        s.head
    )));
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    return layersContract.getTokenUri(tokenId);
  }

  function uploadAllowedPaths(uint8 layer, uint8 option, uint8[] calldata allowedPathsToNextLevel) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint8 x = 0; x < allowedPathsToNextLevel.length; x++) {
      allowedCombinations[layer][option].push(allowedPathsToNextLevel[x]);
    }
  }

  

  //overrides
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, AccessControl)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}
