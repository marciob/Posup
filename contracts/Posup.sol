// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Posup is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Posup", "POSUP") {}

    uint256 campCounter;

    mapping(uint256 => Campaigns) public Camps;
    mapping(address => bool) isCampCreator;

    struct Campaigns {
        uint campId;
        string campName;
        string campURI;
        address campOwner;
        bool isCampActive;
    }

    //modifier to restrict the access to the campaigning owner
    //the campaigning owner address is the donation contract
    modifier onlyCampOwner(uint _campCounter) {
        require(
            msg.sender == Camps[_campCounter].campOwner,
            "Not a campaigning owner"
        );
        _;
    }

    event CampAdded(
        uint256 campCounter,
        string _campName,
        address _campOwner,
        string _campURI
    );

    event posupBurn(address to, uint256 tokenId, uint _campCounter);
    event mintPosup(address to, uint _campCounter);

    //mint a Posup NFT
    //it should be called by the donation contract
    function safeMint(address to, uint _campCounter)
        public
        onlyCampOwner(_campCounter)
    {
        require(Camps[campCounter].isCampActive, "Campaigning is not active");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Camps[_campCounter].campURI);

        emit mintPosup(to, tokenId);
    }

    //create a campaigning and set the campaigning owner
    //the campaigning owner to be set is a donation contract
    function createCamp(
        string memory _campName,
        address _campOwner,
        string memory _campURI
    ) external {
        campCounter++;

        Camps[campCounter].campId = Camps[campCounter].campId++;
        Camps[campCounter].campName = _campName;
        Camps[campCounter].campOwner = _campOwner;
        Camps[campCounter].campURI = _campURI;

        emit CampAdded(campCounter, _campName, _campOwner, _campURI);
    }

    //Posup foundation can call this function to manage if a campaigning should be active or not
    function manageCamp(uint _campCounter, bool _manage) external onlyOwner {
        Camps[_campCounter].isCampActive = _manage;
    }

    //function to be called by the donation contract when necessary to modify a metadata
    function setCampURI(uint _campCounter, string memory _campURI)
        external
        onlyCampOwner(_campCounter)
    {
        Camps[_campCounter].campURI = _campURI;
    }

    //function to be called by the donation contract when finishing the campaigning
    function closeCamp(uint _campCounter) external onlyCampOwner(_campCounter) {
        Camps[_campCounter].isCampActive = false;
    }

    //function used in case of a compromised event for a wallet
    //it burns the token and mints it to a new wallet address
    function burnAnDTransfer(
        address to,
        uint256 tokenId,
        uint _campCounter
    ) external onlyOwner {
        _burn(tokenId);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Camps[_campCounter].campURI);

        emit posupBurn(to, tokenId, _campCounter);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            from == address(0) || to == address(0),
            "Not allowed to transfer token, it's a Soulbound Token"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
