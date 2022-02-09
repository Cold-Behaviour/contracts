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

  uint public combinationCount;
  ILayers public layersContract;
  uint8 public maxMintPerAddress;
  uint public minted = 0;
  bool public mintingStarted;
  uint public mintPrice;
  address public teamAddress;

  //State Mappings
  mapping (uint => uint[]) public combinations; // combo Id => layer[]
  mapping (uint => uint) public comboToToken; //combo Id => (token Id + 1) - to overcome initial state of 0 
  mapping (uint => uint) public tokenToCombo; // token => combo Id

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

  function generate(uint tokenId, uint rand) internal returns (uint[] memory t) {
    rand = rand % MAX_TOKENS;
    while (1 < 2) {
      if (comboToToken[rand] == 0) {
        break;
      }
      rand++;
    }

    comboToToken[rand] = tokenId + 1;
    tokenToCombo[tokenId + 1] = rand;

    return combinations[rand];
  }

  function getTokenData(uint256 tokenId) external override view returns (uint[] memory) {
    uint comboId = tokenToCombo[tokenId + 1];
    return combinations[comboId];
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

  function random(uint seed) internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(
    tx.origin,
    blockhash(block.number - 1),
    block.timestamp,
    seed
    )));
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    return layersContract.getTokenUri(tokenId);
  }

  function uploadCombinations(uint[][] calldata _combinations) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint combo = 0; combo < _combinations.length; combo++) {
      combinations[combinationCount] = _combinations[combo];
      combinationCount++;
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
