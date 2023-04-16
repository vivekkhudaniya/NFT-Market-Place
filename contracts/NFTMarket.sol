//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    // _tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIds;
    // _itemsSold keeps track of the number of items sold on the marketplace
    Counters.Counter private _itemsSold;
    // owner is the contract address that deploy the smart contract
    address payable owner;
    // The fee charged by the marketplace to be allowed to list an NFT
    uint256 listPrice = 0.01 ether;

    // The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    // the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    constructor() ERC721("TokenER721", "TNFT") {
        owner = payable(msg.sender);
    }

    // Updates the listing price of the contract
    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    // Returns the listing price of the contract
    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    // Returns the current number of tokens sold
    function getItemSold() public view returns (uint256) {
        return _itemsSold.current();
    }

    // Returns the latest listed Token that was created
    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getOwnerOfToken(uint256 tokenId) public view returns(address payable _owner){
        _owner = idToListedToken[tokenId].owner;
    }

    // Returns the listed Token of the given tokenId
    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    // Returns the most recent minted tokenId
    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    // The first time a token is created, it is listed here
    // Mints a token and lists it in the marketplace
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        // Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Mint the NFT with tokenId newTokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);

        // Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        // Helper function to update Global variables and emit an event
        createListedToken(newTokenId, price);

        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        // Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Price must be equal to listing price");
        // Make sure the price isn't negative
        require(price > 0, "Price must be at least 1 wei");

        // Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        // Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            false
        );
    }

    // Allows someone to resell a token they have purchased
    function resellToken(uint256 tokenId, uint256 price) public payable {
        // Make sure only owner calls this function
        require(idToListedToken[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        // Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Price must be equal to listing price");
        // Make sure the price isn't negative
        require(price > 0, "Price must be at least 1 wei");

        idToListedToken[tokenId].sold = false;
        idToListedToken[tokenId].price = price;
        idToListedToken[tokenId].seller = payable(msg.sender);
        idToListedToken[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);

        // Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            false
        );
    }

    // This will return all the NFTs currently listed to be sold on the marketplace
    function fetchMarketNFTs() public view returns (ListedToken[] memory){
        uint nftCount = _tokenIds.current();
        uint currentIndex = 0;

        ListedToken[] memory tokens = new ListedToken[](nftCount);
        for(uint i = 1; i < nftCount; i++){
            if(idToListedToken[i].owner == address(this)){
                uint currentId = i;
                ListedToken storage currentToken = idToListedToken[currentId];
                tokens[currentIndex] = currentToken;
                currentIndex++;
            }
        }
        // the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    
    // Returns only items that a user has purchased
    function fetchMyNFTs() public view returns (ListedToken[] memory) {
        uint totalNftCount = _tokenIds.current();
        uint nftCount = 0;
        uint currentIndex = 0;

        // Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=1; i < totalNftCount; i++)
        {
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender){
                nftCount++;
            }
        }

        // Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        for(uint i=1; i < totalNftCount; i++) {
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
                uint currentId = i;
                ListedToken storage currentNft = idToListedToken[currentId];
                tokens[currentIndex] = currentNft;
                currentIndex++;
            }
        }
        return tokens;
    }

    // Returns only items a user has listed
    function fetchMyListedNFTs() public view returns (ListedToken[] memory){
        uint totalNftCount = _tokenIds.current();
        uint nftCount = 0;
        uint currentIndex = 0;

        // Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=1; i < totalNftCount; i++)
        {
            if(idToListedToken[i].seller == msg.sender){
                nftCount++;
            }
        }

        // Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        for(uint i=1; i < totalNftCount; i++) {
            if(idToListedToken[i].seller == msg.sender) {
                uint currentId = i;
                ListedToken storage currentNft = idToListedToken[currentId];
                tokens[currentIndex] = currentNft;
                currentIndex++;
            }
        }
        return tokens;
    }
    

    // Execute the sale of a marketplace item
    // Transfers ownership of the item, as well as funds between parties
    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        require(msg.value == price, "Price must be equal to price");
        address payable seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        // update the details of the token
        idToListedToken[tokenId].owner = payable(msg.sender);
        idToListedToken[tokenId].sold = true;
        idToListedToken[tokenId].seller = payable(address(0));
        _itemsSold.increment();

        // Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        // approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        // Transfer the listing fee to the marketplace creator
        owner.transfer(listPrice);
        // Transfer the proceeds from the sale to the seller of the NFT
        seller.transfer(msg.value);
    }
}