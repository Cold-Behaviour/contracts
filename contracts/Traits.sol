// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IArtist.sol";
import "./ITraits.sol";

contract Traits is ITraits, Ownable {
  using Strings for uint256;

  struct Trait {
    string name;
    string png;
  }

  IArtist public artist;
  uint16 dimensions;

  constructor(uint16 _dimensions) {
    require(_dimensions < 65536, "Number is too large and will cause an overflow exception");
    dimensions = _dimensions;
  }

  string[10] _traitTypes = [
    "background",
    "skin",
    "neck",
    "head",
    "mouth",
    "beard",
    "eyes",
    "clothes",
    "earrings",
    "glasses"
  ];

  mapping(uint8 => mapping(uint8 => Trait)) public traitData;

  /* contract owner to upload names and images of each trait as base64 encoded PNGs */
  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Ids should match the number of traits");
    for (uint x = 0; x < traits.length; x++) {
      traitData[traitType][traitIds[x]] = Trait(
        traits[x].name,
        traits[x].png
      );
    }
  }

  /* generates a data uri for the source of an image element */
  function drawTrait(Trait memory trait) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<image x="0" y="0" width="',
      Strings.toString(dimensions),
      '" height="',
      Strings.toString(dimensions),
      '" image-rendering="pixelated" preserveAspectRatio="xMidyMid" xlink:href="data:image/png;base64,', 
      trait.png,
      '" />'  
    ));
  }

  /* generates a SVG file from the layered PNGs */
  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IArtist.Person memory a = artist.getTokenTraits(tokenId);
    string memory svgString = string(abi.encodePacked(
      drawTrait(traitData[0][a.background]),
      drawTrait(traitData[1][a.skin]),
      drawTrait(traitData[2][a.neck]),
      drawTrait(traitData[3][a.head]),
      drawTrait(traitData[4][a.mouth]),
      drawTrait(traitData[5][a.beard]),
      drawTrait(traitData[6][a.eyes]),
      drawTrait(traitData[7][a.clothes]),
      drawTrait(traitData[8][a.earrings]),
      drawTrait(traitData[9][a.glasses])
    ));

    return string(abi.encodePacked(
      '<svg id="woolf" width="100%" height="100%" version="1.1" viewBox="0 0 ',
      Strings.toString(dimensions),
      ' ',
      Strings.toString(dimensions),
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  /* generates an attribute according to the OpenSea Metadata standard */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /* compiles a collection of attributes for according to the OpenSea Metadata standard */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IArtist.Person memory a = artist.getTokenTraits(tokenId);
    string memory traits = string(abi.encodePacked(
      '[',
      attributeForTypeAndValue(_traitTypes[0], traitData[0][a.background].name),
      attributeForTypeAndValue(_traitTypes[1], traitData[1][a.skin].name), ',',
      attributeForTypeAndValue(_traitTypes[2], traitData[2][a.neck].name), ',',
      attributeForTypeAndValue(_traitTypes[3], traitData[3][a.head].name), ',',
      attributeForTypeAndValue(_traitTypes[4], traitData[4][a.mouth].name), ',',
      attributeForTypeAndValue(_traitTypes[5], traitData[5][a.beard].name), ',',
      attributeForTypeAndValue(_traitTypes[6], traitData[6][a.eyes].name), ',',
      attributeForTypeAndValue(_traitTypes[7], traitData[7][a.clothes].name), ',',
      attributeForTypeAndValue(_traitTypes[8], traitData[8][a.earrings].name), ',',
      attributeForTypeAndValue(_traitTypes[9], traitData[9][a.glasses].name), ']'
    ));

    return traits;
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
