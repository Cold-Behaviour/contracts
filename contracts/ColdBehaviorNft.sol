// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ColdBehaviorNft is ERC721, AccessControl {
  //Usings
  using Strings for uint256;

  //Structs
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

  struct Trait {
    string cid;
    string name;
  }
  
  //Constants
  uint public constant MAX_TOKENS = 8888;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");

  //State Variables
  uint8[][][] public allowedCombinations;  //uint8[layer][option][path_to_item_indexes_in_next_level]
  uint16 dimensions;
  string[9] layers = ["background","body","eyes","teeth","garment","chain","face","ear","head"];
  
  uint8 maxMintPerAddress;
  uint minted = 0;
  bool mintingStarted;
  uint public mintPrice;
  address public teamAddress;

  //State Mappings
  mapping (uint256 => Person) public tokenTraits; // token Id => Person
  mapping (uint8 => mapping(uint8 => Trait)) public traitData;  // layer => option => Trait
  
  //Events

  //Constructor
  constructor(address _team) ERC721("Artist", "CBA") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(WHITELIST_ADMIN_ROLE, msg.sender);

    dimensions = 1024;
    mintPrice = 0.3 ether;
    maxMintPerAddress = 2;
    mintingStarted = false;

    teamAddress = _team;
  }

  //Functions
  function addMinter(address[] memory _minters) external onlyRole(WHITELIST_ADMIN_ROLE) {
    for (uint x = 0; x < _minters.length; x++) {
      _grantRole(MINTER_ROLE, _minters[x]);
    }
  }

  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    Person memory a = getTokenTraits(tokenId);
    string memory traits = string(abi.encodePacked(
      '[',
      attributeForTypeAndValue(layers[0], traitData[0][a.background].name),
      attributeForTypeAndValue(layers[1], traitData[1][a.body].name), ',',
      attributeForTypeAndValue(layers[2], traitData[2][a.eyes].name), ',',
      attributeForTypeAndValue(layers[3], traitData[3][a.teeth].name), ',',
      attributeForTypeAndValue(layers[4], traitData[4][a.garment].name), ',',
      attributeForTypeAndValue(layers[5], traitData[5][a.chain].name), ',',
      attributeForTypeAndValue(layers[6], traitData[6][a.face].name), ',',
      attributeForTypeAndValue(layers[7], traitData[7][a.ear].name), ',',
      attributeForTypeAndValue(layers[8], traitData[8][a.head].name), ','
    ));

    return traits;
  }

  function drawSVG(uint256 tokenId) public view returns (string memory) {
    Person memory a = getTokenTraits(tokenId);
    string memory svgString = string(abi.encodePacked(
      drawTrait(traitData[0][a.background]),
      drawTrait(traitData[1][a.body]),
      drawTrait(traitData[2][a.eyes]),
      drawTrait(traitData[3][a.teeth]),
      drawTrait(traitData[4][a.garment]),
      drawTrait(traitData[5][a.chain]),
      drawTrait(traitData[6][a.face]),
      drawTrait(traitData[7][a.ear]),
      drawTrait(traitData[8][a.head])
    ));

    return string(abi.encodePacked(
      '<svg id="artist" width="100%" height="100%" version="1.1" viewBox="0 0 ',
      Strings.toString(dimensions),
      ' ',
      Strings.toString(dimensions),
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }
  
  function drawTrait(Trait memory trait) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<image x="0" y="0" width="',
      Strings.toString(dimensions),
      '" height="',
      Strings.toString(dimensions),
      '" image-rendering="pixelated" preserveAspectRatio="xMidyMid" xlink:href="https://ipfs.io/ipfs/', 
      trait.cid,
      '" />'  
    ));
  }

  function generate(uint256 tokenId, uint256 rand) internal returns (Person memory t) {
    t = selectOptions(rand);
    if (tokenTraits[structToHash(t)] == 0) {
        tokenTraits[tokenId] = t;
        tokenTraits[structToHash(t)] = tokenId;
        return t;
    }
    return generate(tokenId, random(rand));
  }

  function getTokenTraits(uint256 tokenId) internal view returns (Person memory) {
    return tokenTraits[tokenId];
  }

  function mint(uint8 amount) public payable onlyRole(MINTER_ROLE) {
    require(mintingStarted, "Minting has not yet started");
    require(msg.value >= (mintPrice * amount), "The amount specified does not match the minimum mint price");
    require(_balances[msg.sender] < maxMintPerAddress, "You may not mint any more tokens with this address");
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

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      'Artist #',
      tokenId.toString(),
      '", "description": "Blah Blah Blah.", "image": "data:image/svg+xml;base64,',
      base64(bytes(drawSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  function uploadAllowedPaths(uint8 layer, uint8 option, uint8[] calldata allowedPathsToNextLevel) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint8 x = 0; x < allowedPathsToNextLevel.length; x++) {
      allowedCombinations[layer][option].push(allowedPathsToNextLevel[x]);
    }
  }

  function uploadTraits(uint8 layer, Trait[] calldata traits) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint8 x = 0; x < traits.length; x++) {
      traitData[layer][x] = Trait(
        traits[x].name,
        traits[x].cid
      );
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

  //utility functions
  /** BASE 64 - Written by Brech Devos */
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }
}
