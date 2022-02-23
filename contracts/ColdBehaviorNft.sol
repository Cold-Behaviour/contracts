// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ColdBehaviorNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;

    uint public constant MAX_TOKENS = 8888;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    string public baseUri;

    constructor() ERC721("Cold Behavior NFT", "CBN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        baseUri = "https://ipfs.coldbehavior.com/";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_TOKENS, "No more tokens are available to mint");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setBaseUri(string memory _baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
      baseUri = _baseUri;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}