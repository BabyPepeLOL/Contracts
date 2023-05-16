// SPDX-License-Identifier: MIT

// **********************************&@****@@############@*************************
// ******************************%@##########################@*********************
// **************************@######### # #/#.##(#/###########@********************
// *************************###################################********************
// ************************########.####,# #### ### *#### #####********************
// ***********************@####################################@*******************
// ************************((@###########&@%###################@*******************
// **********************((((((((%###&@@@@@########@@@@&%&@@@@@####&@**************
// ********************@(((((((((((((((((((@(((((((((((((((((((***(&####***********
// *******************@(((((((((@(@            @((((((@.      /@@******************
// ******************((((((((((        @@@@@@@    @/               .***************
// ****************@(((((((((@      @@@@@@@    @@  @  .@@@@@@@@@@@    /************
// ***************#(((((((((@      @@@@@        @@@  @@@         @@@   ************
// **************/(((((((((((@     @@@@@@@     @@@@ @@@@@@@     @@@@  @************
// **************(((((((((((((((   @@@@@@ @@@@@@@@& *@@@@  @@@@@@@@@ @*************
// *************(((((((((((((((((((% @@@@@@@@@@@@(((# @@@@@@@@@@@@(@***************
// ************(((((((((((((((((((((@(((((((@((((((((((((@@@@((@@******************
// ***********@(((((((((((((((((((#(((((@((((@((((((((((@(((((((@******************
// ************@((((((((((((((@(((((((@(((((((((((((((((((((@@(((******************
// ***************((((((((((((((((&%(((((((((((((((((((((((((@@********************
// ********************@((((((((((((((((((@@(((@(((((((((((@(@*********************
// ************************************#@@@@@@(((((((((((((@***********************
// *******************************************&(((@((((@@((@***********************
// *********************************************(((((((((((************************
// ***********************************************((@@/****************************

pragma solidity ^0.8.0;

// Import necessary OpenZeppelin libraries
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Define the PepeNFTandAirdrop contract, which inherits from ERC721 and Ownable
contract PepeNFTandAirdrop is ERC721, Ownable {
    using Address for address; // Utility library for address type

    IERC20 public babyPepeToken; // ERC20 Token
    IERC20 public pepeToken; // ERC20 Token
    mapping(address => bool) public hasMinted; // Track if an address has minted a token
    mapping(address => bool) public hasClaimed; // Track if an address has claimed airdrop

    uint256 public totalAirdropSupply; // Total supply for airdrop
    uint256 public mintedCount; // Count of minted tokens
    uint256 public minPepeBalance; // Minimum Pepe balance to mint a token
    uint256 public minEthBalance; // Minimum Ether balance to mint a token

    bool public mintPaused = true; // Pause minting
    bool public claimPaused = true; // Pause claiming

    // Events
    event Minted(address indexed user, uint256 tokenId);
    event Claimed(address indexed user, uint256 amount);

    // Constructor for the PepeNFTandAirdrop contract
    constructor(address _babyPepeToken, address _pepeToken) ERC721("Pepe Holder NFT", "PEPENFT") {
        require(_babyPepeToken.isContract(), "_babyPepeToken must be a contract address");
        require(_pepeToken.isContract(), "_pepeToken must be a contract address");

        babyPepeToken = IERC20(_babyPepeToken); // Set BabyPepe token
        pepeToken = IERC20(_pepeToken); // Set Pepe token
    }

    // Set the total airdrop supply
    function setTotalAirdropSupply(uint256 _totalAirdropSupply) public onlyOwner {
        totalAirdropSupply = _totalAirdropSupply;
    }

    // Set the minimum Pepe balance required to mint a token
    function setMinPepeBalance(uint256 _minPepeBalance) public onlyOwner {
        minPepeBalance = _minPepeBalance;
    }

    // Set the minimum Ether balance required to mint a token
    function setMinEthBalance(uint256 _minEthBalance) public onlyOwner {
        minEthBalance = _minEthBalance;
    }

    // Pause minting of tokens
    function pauseMint() public onlyOwner {
        mintPaused = true;
    }

    // Unpause minting of tokens
    function unpauseMint() public onlyOwner {
        mintPaused = false;
    }

    // Pause claiming of tokens
    function pauseClaim() public onlyOwner {
        claimPaused = true;
    }

    // Unpause claiming of tokens
    function unpauseClaim() public onlyOwner {
        claimPaused = false;
    }

    // Mint tokens
    function mint() public {
        require(!mintPaused, "Minting is paused");
        require(!hasMinted[msg.sender], "Address has already minted");
        require(pepeToken.balanceOf(msg.sender) >= minPepeBalance, "Must hold minimum Pepe");
        require(msg.sender.balance >= minEthBalance, "Must hold minimum Ether");

        // Increment the minted count and mint the token
        mintedCount++;
        _mint(msg.sender, mintedCount);

        // Mark that the sender has minted a token
        hasMinted[msg.sender] = true;

        // Emit the Minted event
        emit Minted(msg.sender, mintedCount);
    }

    // Function for users to claim their airdropped tokens
    function claim() public {
        // Check that claiming is not paused, the user has minted a token, and has not already claimed
        require(!claimPaused, "Claiming is paused");
        require(hasMinted[msg.sender], "Must mint NFT first");
        require(!hasClaimed[msg.sender], "Address has already claimed");

        // Calculate the amount to airdrop (total airdrop supply divided by the number of minted tokens)
        uint256 amount = totalAirdropSupply / mintedCount;

        // Check that there are enough tokens in the contract for the airdrop
        require(babyPepeToken.balanceOf(address(this)) >= amount, "Not enough tokens for airdrop");

        // Transfer the airdrop tokens to the user
        babyPepeToken.transfer(msg.sender, amount);

        // Mark that the user has claimed their airdrop
        hasClaimed[msg.sender] = true;

        // Emit the Claimed event
        emit Claimed(msg.sender, amount);
    }
}

