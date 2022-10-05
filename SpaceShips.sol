// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceShip is ERC1155, Ownable {
    mapping (uint256 => string) private URIs;
    mapping (address => uint256) public whitelistedAddresses;
    mapping (uint256 => uint) public expirationDate;

    constructor() ERC1155("") {}

    function getTokenUri(uint256 _TokenID) public view returns (string memory) {
      return(URIs[_TokenID]);
    }

    function setTokenUri(uint256 _TokenID, string memory _uri) public onlyOwner {
      URIs[_TokenID] = _uri;
    }

    function setExpirationDate(uint256 _TokenID, uint numberOfDays) public onlyOwner {
      expirationDate[_TokenID] = block.timestamp + (numberOfDays * 1 days);
    }

    function isTokenNotExpired(uint256 _TokenID) public view returns (bool) {
      return block.timestamp < expirationDate[_TokenID];
    }

    function mint(address _Recipient, uint256 _TokenID, uint256 _Amount) public onlyOwner {
      _mint(_Recipient, _TokenID, _Amount, "");
    }

    function updateWhitelistedAddresses(address _Address, uint256 _Amount) public onlyOwner {
      whitelistedAddresses[_Address] = _Amount;
    }

    function whitelistMint(address _Recipient, uint256 _TokenID, uint256 _Amount) public {
      require( _Amount >= 1, "Insufficient Amount!");
      require(whitelistedAddresses[msg.sender] >= _Amount, "This Address Is Not Whitelisted Yet!");
      _mint(_Recipient, _TokenID, _Amount, "");
      whitelistedAddresses[msg.sender] -= _Amount;
    }
}