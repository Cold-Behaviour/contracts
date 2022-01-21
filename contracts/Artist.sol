// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IArtist.sol";

contract Artist is IArtist, ERC721, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public mintPrice;

    //mapping from tokenId to struct containing traits
    mapping (uint256 => Person) public tokenTraits;

    //mapping from address to bool of allowed minters
    mapping(address => bool) public minters;


    constructor() ERC721("Artist", "CBA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        mintPrice = 0.3 ether;
    }
    
    function addMinter(address[] memory _minters) external onlyRole(MINTER_ROLE) {
        for (uint x = 0; x < _minters.length; x++) {
            minters[_minters[x]] = true;
        }
    }

    function removeMinter(address[] memory _minters) external onlyRole(MINTER_ROLE) {
        for (uint x = 0; x < _minters.length; x++) {
            minters[_minters[x]] = false;
        }
    }

    function setMintPrice(uint _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _mintPrice;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getTokenTraits(uint256 tokenId) external view override returns (Person memory) {
        return tokenTraits[tokenId];
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