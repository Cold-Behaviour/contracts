// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/erc721a.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ColdBehaviorNFT is ERC721A, AccessControl {
    using Strings for uint256;

    bool public activeMint = false;
    bool public activePresale = false;
    uint256 public mintPerAddress = 3;
    uint256 public mintCost;
    uint256 public presaleCost;
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    address public teamAddress;

    string public baseUri;
    uint256 public maxTokens = 5555;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(address _teamAddress) ERC721A("Cold Behavior NFT", "CBN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        baseUri = "https://ipfs.coldbehavior.com/";
        teamAddress = _teamAddress;

        mintCost = block.chainid == 1 ? 0.17 ether : 0.0001 ether;
        presaleCost = block.chainid == 1 ? 0.15 ether : 0.0001 ether;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function addWhitelist(address[] calldata members)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 x = 0; x < members.length; x++) {
            if (!hasRole(WHITELIST_ROLE, members[x])) {
                _grantRole(WHITELIST_ROLE, members[x]);
            }
        }
    }

    function devClaim(address recipient, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 ownedTokens = balanceOf(msg.sender);
        require(
            amount + ownedTokens <= mintPerAddress,
            "Exceeded minting limit"
        );
        _safeMint(recipient, amount);
    }

    function mint(uint256 amount) public payable {
        require(activeMint, "Public mint has not started");
        require(
            msg.value == amount * mintCost,
            "Transaction value does not match the mint cost"
        );
        uint256 ownedTokens = balanceOf(msg.sender);
        require(
            amount + ownedTokens <= mintPerAddress,
            "Exceeded minting limit"
        );

        _safeMint(msg.sender, amount);
    }

    function presaleMint(uint256 amount)
        public
        payable
        onlyRole(WHITELIST_ROLE)
    {
        require(activePresale, "Presale mint has not started");
        require(
            msg.value == amount * presaleCost,
            "Transaction value does not match the mint cost"
        );
        uint256 ownedTokens = balanceOf(msg.sender);
        require(
            amount + ownedTokens <= mintPerAddress,
            "Exceeded minting limit"
        );

        _safeMint(msg.sender, amount);
    }

    function setBaseUri(string memory _baseUri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseUri = _baseUri;
    }

    function setMaxTokens(uint256 max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(max > totalSupply(), "New max cannot exceed existing supply");
        maxTokens = max;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = totalSupply();
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint i = 0;
            for (index = 0; index < tokenCount; index++) {
                if (ownerOf(index) == _owner) {
                    result[i] = index;
                    i++;
                }
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

    function toggleMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        activeMint = !activeMint;
        mintPerAddress = 5;
    }

    function togglePresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        activePresale = !activePresale;
        mintPerAddress = 3;
    }

    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(teamAddress).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
