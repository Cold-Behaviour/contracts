// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ColdBehaviorNFT is ERC721, ERC721Enumerable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_MINT_PER_ADDRESS = 2;
    uint256 public mintCost;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");
    address public teamAddress;

    Counters.Counter private _tokenIdCounter;
    string public baseUri;
    uint256 public maxTokens = 8888;
    
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(address _teamAddress) ERC721("Cold Behavior NFT", "CBN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        baseUri = "https://ipfs.coldbehavior.com/";
        teamAddress = _teamAddress;

        mintCost = block.chainid == 1 ? 0.3 ether : 0.0001 ether;

        _grantRole(WITHDRAWAL_ROLE, teamAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function devClaim() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxTokens, "No more tokens are available to mint");

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function mint(uint256 amount)
        public
        payable
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(
            msg.value == amount * mintCost,
            "Transaction value does not match the mint cost"
        );
        uint256 ownedTokens = balanceOf(msg.sender);
        require(
            amount + ownedTokens <= MAX_MINT_PER_ADDRESS,
            "Exceeded minting limit"
        );

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(
                tokenId < maxTokens,
                "No more tokens are available to mint"
            );

            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function nextTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function setBaseUri(string memory _baseUri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseUri = _baseUri;
    }

    function setMaxTokens(uint max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(max > totalSupply(), "New max cannot exceed existing supply");
        maxTokens = max;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function withdraw() external payable onlyRole(WITHDRAWAL_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
