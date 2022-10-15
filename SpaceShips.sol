// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceShipNFT is ERC1155, Ownable {

    address private Owner;                
    address constant private _TokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
    bool private ETHMint = false;
    uint private OneDayInBlockHeight = 7150;
    uint256 private DogelonAmountToTransfer = 40000000;

    struct NewGeneration{
      uint256 ID;
      string Uri;
      string BluePrintUri;
      uint256 Price;
      uint256 MaxSupply;
      uint256 CurrentSupply;
      uint BuildDays;
      bool Unlocked;  
    }  
    NewGeneration[] private Generations; 

    mapping (uint256 => bool) private FullyBuiltTokens;
    mapping (uint256 => bool) private MintedTokens;
    mapping (uint256 => address) private TokensOwners;
    mapping (address => uint) private TokensOwnersBlockHeight;

    function InitializeGenerations() private {
      Generations.push(NewGeneration(0, "", "", 0, 0, 0, 0, false));  
    }

    constructor() ERC1155("") {
      Owner = msg.sender;
      InitializeGenerations();
    }
   
    function TransferContractOwnerShip (address NewOwner) public onlyOwner {
      transferOwnership(NewOwner);
    }

    modifier MintConditions(uint256 _GenerationID) {
      require(IsGenerationUnlocked(_GenerationID), "This Generation Is Not Unlocked Yet!");
      require(Generations[_GenerationID].CurrentSupply < Generations[_GenerationID].MaxSupply, "Max Supply Exceeded!");
      _;
    }

    modifier TokenIDConditions(uint256 _TokenID) {
      require(_TokenID >= 1, "Invalid Token ID!");
      require(Generations[Generations.length - 1].MaxSupply >= _TokenID, "Invalid Token ID!"); 
      _;
    }

    function AddNewGeneration(uint256 _ID, string memory _Uri, string memory _BluePrintUri, uint256 _Price, uint256 _MaxSupply, uint256 _CurrentSupply, uint _BuildDays, bool _Unlocked) public onlyOwner { 
      uint _BuildDaysInBlockHeight = _BuildDays * OneDayInBlockHeight;
      Generations.push(NewGeneration(_ID, _Uri, _BluePrintUri, _Price, _MaxSupply, _CurrentSupply, _BuildDaysInBlockHeight, _Unlocked)); 
     }  

    function UnlockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID].Unlocked = true;
    }

    function LockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID].Unlocked = false;
    }

    function GenerationsCount() public view onlyOwner returns (uint256) {
      return(Generations.length);
    }

    function ExtractGenerationIDByTokenID(uint256 _TokenID) private view returns (uint256) {  
      uint256 I = 1;
      uint256 GenerationID;
      uint256 GenerationsArrayLength = Generations.length - 1;      
      while (I <= GenerationsArrayLength) {       
        if (Generations[I].MaxSupply >= _TokenID) {
          GenerationID = Generations[I].ID;
          break;
        } 
        I++;
      }
      return(GenerationID); 
    }

    function IsGenerationUnlocked(uint256 _GenerationID) private view returns (bool) {
      return(Generations[_GenerationID].Unlocked);
    }

    function ExtractGenerationUri(uint256 _GenerationID) private view returns (string memory) {
      return(Generations[_GenerationID].Uri);
    }

    function uri(uint256 _TokenID) override public view TokenIDConditions(_TokenID) returns (string memory) {    
      string memory MainURI;
      if (FullyBuiltTokens[_TokenID]) {
        MainURI = string(abi.encodePacked(ExtractGenerationUri(ExtractGenerationIDByTokenID(_TokenID)), Strings.toString(_TokenID), ".json"));   
      } else {
        MainURI = Generations[ExtractGenerationIDByTokenID(_TokenID)].BluePrintUri;   
      }     
      return(MainURI);             
    }
   
    function ChangeGenerationURI(uint256 _GenerationID, string memory _NewURI) public onlyOwner {
      Generations[_GenerationID].Uri = _NewURI; 
    }

    function ChangeGenerationBluePrintURI(uint256 _GenerationID, string memory _NewURI) public onlyOwner {
      Generations[_GenerationID].BluePrintUri = _NewURI; 
    }

    function SetTokenAsFullyBuiltByHolder(uint256 _TokenID) public {
      require(TokensOwners[_TokenID] == msg.sender, "Only the specific ship token holder can fully build tokens!");
      require(MintedTokens[_TokenID], "Token Not Minted Yet!");    
      require(TokensOwnersBlockHeight[msg.sender] < block.number, "This Ship Needs More Time To Be Built");
      FullyBuiltTokens[_TokenID] = true;
    }

    function SetTokenAsFullyBuiltByOwner(uint256 _TokenID) public onlyOwner {
      require(MintedTokens[_TokenID], "Token Not Minted Yet!");
      FullyBuiltTokens[_TokenID] = true;
    }

    function GetGenerationRemainingSupply(uint256 _GenerationID) public view onlyOwner returns (uint256) {
      return(Generations[_GenerationID].MaxSupply - Generations[_GenerationID].CurrentSupply);
    }

    function IsShipFullyBuilt (uint256 _TokenID) public view returns (bool) {
      return(FullyBuiltTokens[_TokenID]);
    }

    function WithdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function WithdrawDOGELON (uint256 _Amount) external onlyOwner {
      IERC20(_TokenContract).transfer(Owner, _Amount);
    }

    function SetETHMint (bool _State) public onlyOwner {
      ETHMint = _State;
    }

    function SetOneDayInBlockHeight (uint _DayInBlockHeight) public onlyOwner {
      OneDayInBlockHeight = _DayInBlockHeight;
    } 
    
    function SetDogelonAmountToTransfer (uint256 _DogelonToTransfer) public onlyOwner {
      DogelonAmountToTransfer = _DogelonToTransfer;
    }

    function SetTokenOwner (uint256 _TokenID, address _Owner, uint256 _GenerationID) private {
      MintedTokens[_TokenID] = true;
      TokensOwners[_TokenID] = _Owner;
      TokensOwnersBlockHeight[_Owner] = block.number + Generations[_GenerationID].BuildDays; 
    }

    function Mint_Using_ETH(uint256 _GenerationID) public payable MintConditions(_GenerationID) {   
      require(ETHMint, "Mint Using ETH Is Disabled For Now, Try Using Dogelon!"); 
      require(msg.value >= Generations[_GenerationID].Price, "Not Enough Funds!");        
      unchecked {
        Generations[_GenerationID].CurrentSupply += 1;          
      }     
      uint256 _TokenID = Generations[_GenerationID].CurrentSupply; 
      _mint(msg.sender, _TokenID, 1, "");
      SetTokenOwner(_TokenID, msg.sender, _GenerationID);
    }

    function Mint_Using_DOGELON(uint256 _GenerationID) public payable MintConditions(_GenerationID) {
      IERC20(_TokenContract).transferFrom(msg.sender, Owner, DogelonAmountToTransfer);      
      unchecked {
        Generations[_GenerationID].CurrentSupply += 1;          
      }     
      uint256 _TokenID = Generations[_GenerationID].CurrentSupply; 
      _mint(msg.sender, _TokenID, 1, "");
      SetTokenOwner(_TokenID, msg.sender, _GenerationID);
    }
}