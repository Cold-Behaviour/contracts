// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ColdBehaviorNFT is ERC721, ERC721Enumerable, AccessControl, Pausable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_MINT_PER_ADDRESS = 2;
    uint256 public constant MAX_TOKENS = 8888;
    uint256 public mintCost;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");
    address public teamAddress;

    Counters.Counter private _tokenIdCounter;
    string public baseUri;

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

    function nextTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
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
                tokenId < MAX_TOKENS,
                "No more tokens are available to mint"
            );

            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
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

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function withdraw() external payable onlyRole(WITHDRAWAL_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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
