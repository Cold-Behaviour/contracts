// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./INft.sol";
import "./Base64.sol";

contract Layers is AccessControl {
  //Usings
  using Strings for uint256;

  //Constants
  bytes32 public constant UPLOADER_ROLE = keccak256("UPLOADER_ROLE");

  //Structs
  struct Layer {
    string cid;
    string name;
    string trait;
  }

  //State Variables
  INft public nftContract;
  uint public layerCount;

  //State Mappings
  mapping (uint => Layer) public layerData;  // layer => Name/CID/Trait

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(UPLOADER_ROLE, msg.sender);
  }

  //Functions
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }
  
  function compileAttributes(uint256 tokenId) internal view returns (string memory traits) {
    uint[] memory a = nftContract.getTokenData(tokenId);
    traits = "[";
    for (uint layer = 0; layer < a.length; layer++) {
      traits = concat(traits, attributeForTypeAndValue(layerData[layer].trait, layerData[layer].name));
    }

    return concat(traits, "]");
  }

  function concat(string memory a, string memory b) internal pure returns (string memory) {

    return string(abi.encodePacked(a, b));

  }

  function drawLayer(Layer memory layer) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="0" y="0" width="1024" height="1024" image-rendering="pixelated" xlink:href="https://ipfs.coldbehavior.com/ipfs/', 
      layer.cid,
      '" />'  
    ));
  }

  function drawSVG(uint tokenId) internal view returns (string memory svgString) {
    uint[] memory a = nftContract.getTokenData(tokenId);
    for (uint layer = 0; layer < a.length; layer++) {
      svgString = concat(svgString, drawLayer(layerData[layer]));
    }

    return string(abi.encodePacked(
      '<svg id="artist" width="100%" height="100%" version="1.1" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  function drawSVGTest(uint[] calldata person) external view returns (string memory svgString) {
    for (uint layer = 0; layer < person.length; layer++) {
      svgString = concat(svgString, drawLayer(layerData[layer]));
    }

    return string(abi.encodePacked(
      '<svg id="artist" width="100%" height="100%" version="1.1" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  function getTokenUri(uint256 tokenId) public view returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      'Artist #',
      tokenId.toString(),
      '", "description": "Blah Blah Blah.", "image": "data:image/svg+xml;base64,',
      Base64.base64(bytes(drawSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      Base64.base64(bytes(metadata))
    ));
  }

  function initialize(address _nftContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    nftContract = INft(_nftContract);
  }

  function uploadLayers(Layer[] calldata _layers) external onlyRole(UPLOADER_ROLE) {
    for (uint8 x = 0; x < _layers.length; x++) {
      layerData[layerCount] = Layer(
        _layers[x].name,
        _layers[x].cid,
        _layers[x].trait
      );
      layerCount++;
    }
  }
}
