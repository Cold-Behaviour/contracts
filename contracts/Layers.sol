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
  }

  //State Variables
  string[9] layers = ["background","body","eyes","teeth","garment","chain","face","ear","head"];
  INft nftContract;

  //State Mappings
  mapping (uint8 => mapping(uint8 => Layer)) public layerData;  // layer => option => Name/CID

  constructor() {
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
  
  function compileAttributes(uint256 tokenId) internal view returns (string memory) {
    INft.Person memory a = nftContract.getTokenData(tokenId);
    string memory traits = string(abi.encodePacked(
      '[',
      attributeForTypeAndValue(layers[0], layerData[0][a.background].name),
      attributeForTypeAndValue(layers[1], layerData[1][a.body].name), ',',
      attributeForTypeAndValue(layers[2], layerData[2][a.eyes].name), ',',
      attributeForTypeAndValue(layers[3], layerData[3][a.teeth].name), ',',
      attributeForTypeAndValue(layers[4], layerData[4][a.garment].name), ',',
      attributeForTypeAndValue(layers[5], layerData[5][a.chain].name), ',',
      attributeForTypeAndValue(layers[6], layerData[6][a.face].name), ',',
      attributeForTypeAndValue(layers[7], layerData[7][a.ear].name), ',',
      attributeForTypeAndValue(layers[8], layerData[8][a.head].name), ','
    ));

    return traits;
  }

  function drawLayer(Layer memory layer) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="0" y="0" width="1024" height="1024" image-rendering="pixelated" xlink:href="https://ipfs.io/ipfs/', 
      layer.cid,
      '" />'  
    ));
  }

  function drawSVG(uint256 tokenId) internal view returns (string memory) {
    INft.Person memory a = nftContract.getTokenData(tokenId);
    string memory svgString = string(abi.encodePacked(
      drawLayer(layerData[0][a.background]),
      drawLayer(layerData[1][a.body]),
      drawLayer(layerData[2][a.eyes]),
      drawLayer(layerData[3][a.teeth]),
      drawLayer(layerData[4][a.garment]),
      drawLayer(layerData[5][a.chain]),
      drawLayer(layerData[6][a.face]),
      drawLayer(layerData[7][a.ear]),
      drawLayer(layerData[8][a.head])
    ));

    return string(abi.encodePacked(
      '<svg id="artist" width="100%" height="100%" version="1.1" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  function drawSVGTest(INft.Person calldata person) external view returns (string memory) {
    string memory svgString = string(abi.encodePacked(
      drawLayer(layerData[0][person.background]),
      drawLayer(layerData[1][person.body]),
      drawLayer(layerData[2][person.eyes]),
      drawLayer(layerData[3][person.teeth]),
      drawLayer(layerData[4][person.garment]),
      drawLayer(layerData[5][person.chain]),
      drawLayer(layerData[6][person.face]),
      drawLayer(layerData[7][person.ear]),
      drawLayer(layerData[8][person.head])
    ));

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

  function uploadLayers(uint8 layer, Layer[] calldata _layers) external onlyRole(UPLOADER_ROLE) {
    for (uint8 x = 0; x < _layers.length; x++) {
      layerData[layer][x] = Layer(
        _layers[x].name,
        _layers[x].cid
      );
    }
  }
}
