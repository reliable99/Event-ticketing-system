// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EventTicketing is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _ticketIds;
    mapping(uint256 => uint256) public ticketPrices;
    mapping(uint256 => address) public ticketOrganizers;
    mapping(uint256 => uint256) public royalties;

    event TicketMinted(uint256 ticketId, address owner, uint256 price);
    event TicketResold(uint256 ticketId, address newOwner, uint256 resalePrice);
    event PriceUpdated(uint256 ticketId, uint256 newPrice);

    constructor(address initialOwner) ERC721("DigiEntry", "DENT") Ownable(initialOwner) {}

    
    function mintTicket(
        address organizer,
        string memory tokenURI,
        uint256 price,
        uint256 royalty
    ) public onlyOwner returns (uint256) {
        require(royalty <= 10000, "Royalty cannot exceed 100%");

        _ticketIds.increment();
        uint256 newTicketId = _ticketIds.current();

        _mint(organizer, newTicketId);
        _setTokenURI(newTicketId, tokenURI);

        ticketPrices[newTicketId] = price;
        ticketOrganizers[newTicketId] = organizer;
        royalties[newTicketId] = royalty;

        emit TicketMinted(newTicketId, organizer, price);

        return newTicketId;
    }


    function resellTicket(uint256 ticketId, uint256 resalePrice) public {
        require(ownerOf(ticketId) == msg.sender, "You do not own this ticket");
        require(resalePrice > 0, "Resale price must be greater than zero");

        address organizer = ticketOrganizers[ticketId];
        uint256 royaltyAmount = (resalePrice * royalties[ticketId]) / 10000;

        
        payable(msg.sender).transfer(resalePrice - royaltyAmount);
        
        payable(organizer).transfer(royaltyAmount);

        _transfer(msg.sender, address(this), ticketId);
        ticketPrices[ticketId] = resalePrice;

        emit TicketResold(ticketId, address(this), resalePrice);
    }

    
    function purchaseTicket(uint256 ticketId) public payable {
        require(ticketPrices[ticketId] > 0, "Ticket is not for sale");
        require(msg.value >= ticketPrices[ticketId], "Insufficient funds");

        address seller = ownerOf(ticketId);
        uint256 salePrice = ticketPrices[ticketId];

        _transfer(seller, msg.sender, ticketId);
        ticketPrices[ticketId] = 0;

        payable(seller).transfer(salePrice);
    }

    
    function updateTicketPrice(uint256 ticketId, uint256 newPrice) public {
        require(ownerOf(ticketId) == msg.sender, "You do not own this ticket");
        require(newPrice > 0, "Price must be greater than zero");

        ticketPrices[ticketId] = newPrice;
        emit PriceUpdated(ticketId, newPrice);
    }

    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    
    receive() external payable {}


    fallback() external payable {
        
    }
}
