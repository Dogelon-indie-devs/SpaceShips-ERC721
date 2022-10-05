// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceShip is ERC1155, Ownable {
    mapping (uint256 => string) private URIs;

    // https://ipfs.io/ipfs/bafybeidw47z5awqu3tv4dfg2ooo4ps7co6huw4xhecdh6hzz3ucrcvyyre/{id}.json

    constructor() ERC1155("") {}

    function uri(uint256 _TokenID) override public view returns (string memory) {
      return(URIs[_TokenID]);
    }

    function setTokenUri(uint256 _TokenID, string memory _uri) public onlyOwner {
      URIs[_TokenID] = _uri;
    }

    function mint(address _Recipient, uint256 _TokenID, uint256 _Amount) public onlyOwner {
      _mint(_Recipient, _TokenID, _Amount, "");
    }
}