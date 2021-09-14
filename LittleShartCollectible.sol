// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './LittleShartAdmins.sol';

contract LittleShartCollectible is ERC721, ERC721URIStorage, ERC721Enumerable, LittleShartAdmins {
    
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    
    string public baseURI;
    
    uint256 public price = 100000000000000000 wei;
    
    uint256 public maxTokens;
    uint256 public maxTokensPerMint = 10;
    
    address _gawAddress = 0x7aaA0B5aF303562ddBdec84bf3EbDFD8e23794C1;
    
    bool saleActive;
    
    constructor(
        string memory _baseURI,
        uint256 _maxTokens
    ) ERC721("Little Sharts", "LSHRT") {
        baseURI = _baseURI;
        maxTokens = _maxTokens;
        masterAdmin = msg.sender;
        admins = [msg.sender];
    }
    
    event TokenMinted(address indexed minter, uint amount);
    
    function mintGiveawayTokens() public onlyAdmin {
        for (uint i=0;i<32;i++) {
            uint256 newItemId = _tokenIds.current()+1;
            _safeMint(_gawAddress, newItemId);
            _tokenIds.increment();
        }
    }
    
    function mintShart(
        uint256 amount
    ) payable public {
        require(msg.value >= (amount  * price), "Not enough funds sent to cover transaction!");
        require(saleActive, "Sale is not active!");
        require((_tokenIds.current()+amount) <= maxTokens, "Not enough remaining tokens to mint that many!");
        require(amount <= maxTokensPerMint, "Requested to mint too many tokens!");
        
        for (uint i=0;i<amount;i++) {
            uint256 newItemId = _tokenIds.current()+1;
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
        
        emit TokenMinted(msg.sender, amount);
        
    }
    
    function withdrawFunds() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Balance!");
        payable(masterAdmin).transfer(balance);
    }
    
    function updateURI(string memory newURI) public onlyAdmin {
        baseURI = newURI;
    }
    
    
    function updateMaxTokens(uint256 _maxTokens) public onlyAdmin {
        require(_maxTokens > maxTokens, "New count must be higher than old count!");
        maxTokens = _maxTokens;
    }
    
    function tokensOwned() public view returns (uint256[] memory) {
        uint balance = balanceOf(msg.sender);
        uint256[] memory tOwned = new uint256[](balance);
        for (uint i=0;i<balance;i++) {
            tOwned[i] = tokenOfOwnerByIndex(msg.sender, i);
        }
        return tOwned;
    }
    
    function tokensOwned(address _owner) public view returns (uint256[] memory) {
        uint balance = balanceOf(_owner);
        uint256[] memory tOwned = new uint256[](balance);
        for (uint i=0;i<balance;i++) {
            tOwned[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tOwned;
    }
    
    function tokensRemaining() public view returns (uint256) {
        return maxTokens - _tokenIds.current();
    }
    
    function updateSale(bool status) public onlyAdmin {
        saleActive = status;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    
    function tokenURI(uint256 _id) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(_id), ".json"));
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}
