// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SpaceShip is ERC1155 {
    uint256 public constant SpaceShipID = 1;

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeidw47z5awqu3tv4dfg2ooo4ps7co6huw4xhecdh6hzz3ucrcvyyre/{id}.json") {
        _mint(msg.sender, SpaceShipID, 1, "");
    }
}