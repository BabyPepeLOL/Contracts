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

pragma solidity ^0.8.9;

// Importing OpenZeppelin's contract libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Contract for BabyPepe Liquidity Mining
contract BabyPepeLiquidityMining is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20; // Safe ERC20 transfer library

    // State variables
    IERC20 public babyPepeToken; // BabyPepe Token
    IERC20 public lpToken; // Liquidity Provider Token

    uint256 public epochDuration = 1 days; // Duration of an epoch
    uint256 public rewardRate; // Reward rate
    uint256 public lastEpochUpdateTime; // Last time the epoch was updated
    uint256 public rewardPerTokenStored; // Stored reward per token
    uint256 public totalStaked; // Total staked

    // Mapping to store user data
    mapping(address => uint256) public userEpoch; // The last epoch the user interacted with the contract
    mapping(address => uint256) public userRewardPerTokenPaid; // The already paid reward per token for the user
    mapping(address => uint256) public rewards; // The rewards of the user
    mapping(address => uint256) public staked; // The amount of tokens the user staked

    // Events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    // Constructor
    constructor(address _babyPepeToken, address _lpToken, uint256 _rewardRate) {
        // Check if the provided addresses are contract addresses
        require(Address.isContract(_babyPepeToken), "_babyPepeToken must be a contract address");
        require(Address.isContract(_lpToken), "_lpToken must be a contract address");

        babyPepeToken = IERC20(_babyPepeToken); // Set BabyPepe token
        lpToken = IERC20(_lpToken); // Set LP token
        rewardRate = _rewardRate; // Set reward rate
        lastEpochUpdateTime = block.timestamp; // Set last epoch update time to current time
    }

    // Function to get the current epoch
    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - lastEpochUpdateTime) / epochDuration + 1;
    }

    // Function to stake tokens
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        staked[msg.sender] += amount;
        userEpoch[msg.sender] = currentEpoch();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Function to withdraw staked tokens
    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        totalStaked -= amount;
        staked[msg.sender] -= amount;
        lpToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

        // Function to get rewards
    function getReward() public nonReentrant {
        // Check that the user's last interaction was not in the current epoch
        // This ensures that a user cannot claim rewards for the current epoch
        require(userEpoch[msg.sender] < currentEpoch(), "Cannot claim reward for current epoch");

        // Calculate the reward for the user
        uint256 reward = earned(msg.sender);

        // If the reward is greater than 0
        if (reward > 0) {
            // Reset the rewards of the user
            rewards[msg.sender] = 0;

            // Transfer the rewards to the user
            babyPepeToken.safeTransfer(msg.sender, reward);

            // Emit the RewardPaid event
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Function to calculate earned rewards
    function earned(address account) public view returns (uint256) {
        if (userEpoch[account] >= currentEpoch()) {
            return 0; // No rewards earned if user's last interaction was in the current or future epoch
        }
        return
            (staked[account] * // Stake amount
                (rewardPerToken() - userRewardPerTokenPaid[account])) / // Rewards per token minus already paid rewards per token
            1e18 +
            rewards[account]; // Add already earned rewards
    }

    // Function to calculate rewards per token
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored; // If no tokens staked return stored reward per token
        }
        return
            rewardPerTokenStored + // Stored rewards per token
            (((block.timestamp - lastEpochUpdateTime) * rewardRate * 1e18) / totalStaked); // Add new rewards per token based on time passed since last update
    }

    // Function to update rewards per token and last update time
    function updateReward() internal {
        if (block.timestamp >= lastEpochUpdateTime + epochDuration) {
            rewardPerTokenStored = rewardPerToken(); // Update stored rewards per token
            lastEpochUpdateTime += epochDuration; // Update last epoch update time
        }
    }
}

