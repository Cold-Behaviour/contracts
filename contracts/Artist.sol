// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IArtist.sol";

contract Artist is IArtist, ERC721, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");
    uint public constant MAX_TOKENS = 8888;

    uint public maxMintPerAddress;
    uint16 public minted;
    bool public mintingStarted;
    uint public mintPrice;
    address public teamAddress;

    uint8[][][9] public allowedCombinations;

    mapping(uint => uint) public existingCombinations;
    mapping(address => bool) public minters;
    mapping(address => uint) public tokensOwned;

    //mapping from tokenId to struct containing traits
    mapping (uint256 => Person) public tokenTraits;

    constructor(address _team) ERC721("Artist", "CBA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(WHITELIST_ADMIN_ROLE, msg.sender);

        mintPrice = 0.3 ether;
        maxMintPerAddress = 2;
        mintingStarted = false;

        teamAddress = _team;
    }
    
    function addMinter(address[] memory _minters) external onlyRole(WHITELIST_ADMIN_ROLE) {
        for (uint x = 0; x < _minters.length; x++) {
            minters[_minters[x]] = true;
        }
    }

    function generate(uint256 tokenId, uint256 rand) internal returns (Person memory t) {
        t = selectTraits(rand);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(rand));
    }

    function mint(uint8 amount) public payable {
        require(mintingStarted, "Minting has not yet started");
        require(msg.value >= mintPrice, "The amount specified does not match the minimum mint price");
        require(minters[msg.sender], "You are not a member of the minting whitelist");
        require(tokensOwned[msg.sender] < maxMintPerAddress, "You may not mint any more tokens with this address");
        require(minted + amount <= MAX_TOKENS, "All tokens have been minted");
        
        minted++;
        uint rand = random(minted);
        generate(minted, rand);

        tokensOwned[msg.sender]++;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function removeMinter(address[] memory _minters) external onlyRole(WHITELIST_ADMIN_ROLE) {
        for (uint x = 0; x < _minters.length; x++) {
            minters[_minters[x]] = false;
        }
    }

    function setAllowedCombination(uint8 layer, uint8 variant, uint8[] memory values) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedCombinations[0][variant] = values;
    }

    function setMaxMintPerAddress(uint max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintPerAddress = max;
    }

    function setMintPrice(uint _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _mintPrice;
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

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.timestamp,
        seed
        )));
    }

    // function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    //     _safeMint(to, tokenId);
    // }

    function selectTrait(uint16 rand, uint8 layer) internal view returns (uint8) {
        uint8 option = uint8(rand) % uint8(allowedCombinations[layer].length);
        
        if (rand >> 9 < allowedCombinations[layer][option]) return layer;
        return allowedCombinations[traitType][trait];
    }

    function selectTraits(uint256 rand) internal view returns (Person memory t) {    
        t.background = selectTrait(uint16(rand), 0);
        t.body = selectTrait(uint16(rand), 1);
        t.eyes = selectTrait(uint16(rand), 2);
        t.teeth = selectTrait(uint16(rand), 3);
        t.garment = selectTrait(uint16(rand), 4);
        t.chain = selectTrait(uint16(rand), 5);
        t.face = selectTrait(uint16(rand), 6);
        t.ear = selectTrait(uint16(rand), 7);
        t.head = selectTrait(uint16(rand), 8);
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