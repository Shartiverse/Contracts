// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LittleShartAdmins.sol";
import "./LittleShartCollectible.sol";

contract LittleShartMarketplace is LittleShartAdmins {
    
    using SafeMath for uint256;
    
    uint256 public _listingFee = 2;
    uint256 public _updateFee = 1;
    
    address _nft;

    struct Listing {
        address seller;
        bool isActive;
        uint price;
    }
    
    struct Bid {
        address bidder;
        bool isActive;
        uint value;
    }
    
    mapping (uint256 => Listing) _listings;
    mapping (uint256 => Bid) _bids;
    mapping (address => uint256[]) _tokensListed;
    
    // Locks up until listing is bought or refunds lister if cancelled
    mapping (uint256 => uint256) _pendingFeeTreasury;
    
    // Tracks tokenIds for sale for easy call access
    uint256[] public _tokensForSale;
    
    constructor (
        address _nftAddress
    ) {
        _nft = _nftAddress;
        masterAdmin = msg.sender;
        admins = [masterAdmin];
    }
    
    event ListingBought(uint256 indexed tokenId, address indexed buyer, uint256 indexed price);
    
    function buyNow(uint256 tokenId) public payable {
        /* For Use by Buyers to purchase a listing for list price */
        Listing memory listing = _listings[tokenId];
        require(listing.isActive, "Listing is inactive!"); // Listing must be for sale
        require(listing.seller != msg.sender, "Cannot purchase your own listing!"); // Cannot buy a token you already own/are listing!
        require(msg.value == listing.price, "Value of TXN is not the same as listing price!"); // Buy value must be equal to listing price!
        
        Bid memory bid = _bids[tokenId];
        uint256 bidValue = bid.value;
        if (bid.isActive && (bid.bidder == msg.sender)) { // Check if there is a current bid, and if that bidder is the buyer
            // Buyer is current bidder, refund them their bid
            payable(msg.sender).transfer(bidValue); // Refund
            _bids[tokenId] = Bid(address(0), false, 0); // Reset
        }
        
        LittleShartCollectible(_nft).approve(msg.sender, tokenId); // Approve Ownership
        LittleShartCollectible(_nft).transferFrom(address(this), msg.sender, tokenId); // Transfer to new owner!
        
        if (LittleShartCollectible(_nft).balanceOf(msg.sender) == 1) {
            revert("Transfer did not complete!"); // Transfer failed, revert!
        }

        // Pay the seller
        payable(listing.seller).transfer(msg.value);
        payable(masterAdmin).transfer(_pendingFeeTreasury[tokenId]);
        
        emit ListingBought(tokenId, msg.sender, msg.value);
        
        _removeFromSale(tokenId);
        
    }
    
    event BidAccepted(uint256 indexed tokenId, uint256 indexed price);
    
    function acceptBid(uint256 tokenId) public {
        /* For Use by Sellers to accept the current bid for bid price */
        Listing memory listing = _listings[tokenId];
        require(listing.seller == msg.sender, "Cannot accept bid on listing you do not own!");
        Bid memory bid = _bids[tokenId];
        address bidder = bid.bidder;
        require(bid.isActive, "No active bid to accept!"); // Make sure there is a current bid
        require(bid.value > 0, "Bid value is zero."); // Make sure the bid is valid!
        
        // We know the bid is valid, start the transfer and payment
        LittleShartCollectible(_nft).approve(bidder, tokenId); // Approve Ownership
        LittleShartCollectible(_nft).transferFrom(address(this), bid.bidder, tokenId); // Transfer to new owner
        _bids[tokenId] = Bid(address(0), false, 0); // Reset bid on listing because it was accepted
        
        if (LittleShartCollectible(_nft).balanceOf(bid.bidder) == 1) {
            revert("Transfer did not complete!"); // Transfer failed, revert!
        }
        
        payable(masterAdmin).transfer(_pendingFeeTreasury[tokenId]);
        
        emit BidAccepted(tokenId, bid.value);
        
        _removeFromSale(tokenId);
    }
    
    event BidCancelled(uint256 indexed tokenId);
    
    function cancelBid(uint256 tokenId) public {
        /* For Use by the current bidder to cancel their current bid */
        Bid memory currentBid = _bids[tokenId];
        require(currentBid.isActive, "Bid is not active!");
        require(currentBid.bidder == msg.sender, "You are not owner of this bid!");
        
        uint refundAmnt = currentBid.value;
        
        _bids[tokenId] = Bid(address(0), false, currentBid.value);
        payable(msg.sender).transfer(refundAmnt);
        
        emit BidCancelled(tokenId);
    }
    
    event BidCreated(uint256 indexed tokenId, address indexed bidder, uint256 indexed price);
    
    function createBid(uint256 tokenId) public payable {
        /* For Use by Buyers to create a bid for a listing for a certain price */
        require(msg.value > 0, "Bid Price Cannot Be Negative!");
        Listing memory listing = _listings[tokenId];
        require(listing.isActive, "Listing Must Be Active To Bid!");
        require(listing.seller != msg.sender, "Cannot bid on your own listing!");
        
        Bid memory currentBid = _bids[tokenId];
        // Check if there is already a Bid
        if (currentBid.isActive) {
            // Make sure new bid is greater than old bid
            require(msg.value > currentBid.value, "Too low to outbid current bid!");
            // Refund old bidder
            payable(currentBid.bidder).transfer(currentBid.value);
        }
        
        emit BidCreated(tokenId, msg.sender, msg.value);
        
        _bids[tokenId] = Bid(msg.sender, true, msg.value);
        
    }
    
    event ListingUpdated(uint256 indexed tokenId, uint256 indexed price);
    
    function updateListing(uint256 tokenId, uint256 value) public payable {
        /* For Use by Owners of a listing to update a listing to a new price */
        require(value > 0, "Listing price cannot be negative!"); // Listing Cannot be Negatively Priced
        Listing memory listing = _listings[tokenId];
        require(listing.seller==msg.sender, "Must be owner of token!"); // Must own the token trying to be updated
        require(_listings[tokenId].isActive, "Listing is not active!"); // Listing must be active to update. List it first
        uint256[2] memory amounts = _getFeeAmounts(_updateFee, value);
        
        require(msg.value == amounts[1], "Value does not cover listing fee!");
        _pendingFeeTreasury[tokenId] += amounts[1];

        _listings[tokenId] = Listing(msg.sender, true, value);
        
        emit ListingUpdated(tokenId, value);
    }
    
    event ListingCancelled(uint256 indexed tokenId);
    
    function cancelListing(uint256 tokenId) public {
        /* For Use by Owners of a listing to canel a listing */
        Listing memory listing = _listings[tokenId];
        require(listing.seller == msg.sender, "Must be owner of listing!");
        require(listing.isActive, "Listing must be active!");
        
        // At this point we know the sender is the seller.
        // Lets refund and remove their Listing
        payable(listing.seller).transfer(_pendingFeeTreasury[tokenId]);
        
        LittleShartCollectible(_nft).transferFrom(address(this), msg.sender, tokenId);
        
        emit ListingCancelled(tokenId);
        
        _removeFromSale(tokenId);
    }
    
    event ListingCreated(uint256 indexed tokenId, address indexed seller, uint256 indexed price);
    
    function createListing(uint256 tokenId, uint256 value) public payable {
        /* For Use by Owners of a token to crate a listing for list price */
        require(value > 0, "Listing price cannot be negative!"); // Listing Cannot be Negatively Priced
        require(LittleShartCollectible(_nft).ownerOf(tokenId)==msg.sender, "Must be owner of token!"); // Must own the token trying to be listed
        require(!_listings[tokenId].isActive, "Listing is already active!"); // Listing must be inactive to start. Cancel or Update Otherwise
        uint256[2] memory amounts = _getFeeAmounts(_listingFee, value);
        
        require(msg.value == amounts[1], "Value does not cover listing fee!");


        // Contract Should Be Approved, Transfer to Contract
        LittleShartCollectible(_nft).transferFrom(msg.sender, address(this), tokenId);
        
        require(LittleShartCollectible(_nft).ownerOf(tokenId)==address(this), "Token Transfer Failed!");
        _pendingFeeTreasury[tokenId] = amounts[1];
        _tokensListed[msg.sender].push(tokenId);
        _listings[tokenId] = Listing(msg.sender, true, value);
        _tokensForSale.push(tokenId);
        
        emit ListingCreated(tokenId, msg.sender, value);
        
    }
    
    function getTokensForSale() public view returns (uint256[] memory) {
        return _tokensForSale;
    }
    
    function getTokensListed() public view returns (uint256[] memory) {
        return _tokensListed[msg.sender];
    }
    
    function getTokensListed(address _owner) public view returns (uint256[] memory) {
        return _tokensListed[_owner];
    }
    
    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }
    function getBid(uint256 tokenId) public view returns (Bid memory) {
        return _bids[tokenId];
    }
    
    function getFeeTreasuryAmountForListing(uint256 tokenId) public view onlyAdmin returns (uint256) {
        return _pendingFeeTreasury[tokenId];
    }
    
    function _removeFromSale(uint256 tokenId) internal {
        uint256 tokenIndex;
        for (uint i=0;i<_tokensForSale.length;i++) {
            if (_tokensForSale[i] == tokenId) {
                tokenIndex = i;
            }
        }
        
        _tokensForSale[tokenIndex] = _tokensForSale[_tokensForSale.length-1];
        _tokensForSale.pop();
        
        _listings[tokenId] = Listing(msg.sender, false, 0);
        _pendingFeeTreasury[tokenId] = 0;
        
        uint256 listedIndex;
        for (uint i=0;i<_tokensListed[msg.sender].length;i++) {
            if (_tokensListed[msg.sender][i] == tokenId) {
                listedIndex = i;
            }
        }
        
        _tokensListed[msg.sender][listedIndex] = _tokensListed[msg.sender][_tokensListed[msg.sender].length-1];
        _tokensListed[msg.sender].pop();
    }
    
    function _getFeeAmounts(uint256 fee, uint256 amount) internal pure returns (uint256[2] memory outAmounts) {
        uint256 feeAmount = (amount / 100) * fee;
        uint256 tOut = amount - feeAmount;
        outAmounts[0] = tOut;
        outAmounts[1] = feeAmount;
        
        return outAmounts;
    }
    
}
