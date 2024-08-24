// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

struct Campaign {
    string title;
    string slug;
    string description;
    address payable benefactor;
    uint256 goal;
    uint256 deadline;
    bool isActive;
    uint256 amountRaised;
}

contract Crowdfunding is ReentrancyGuard {
    modifier isValidCampaign(string memory campaignSlug) {
        Campaign memory campaign = allCampaigns[campaignSlug];

        if (keccak256(abi.encodePacked(campaign.slug)) != keccak256(abi.encodePacked(campaignSlug))) {
            revert("Campaign not found");
        }

        if (!campaign.isActive) {
            revert("Campaign ended");
        }
        _;
    }

    mapping(string => Campaign) public allCampaigns;

    address private contractOwner;

    event CampaignCreated(string slug, string title, address indexed benefactor, uint256 goal, uint256 deadline);

    event DonationReceived(string slug, address indexed donor, uint256 amount);

    event CampaignEnded(string slug, uint256 amountRaised);

    constructor() {
        contractOwner = msg.sender;
    }

    function createCampaign(
        string memory slug,
        string memory title,
        string memory description,
        address payable benefactor,
        uint256 goal,
        uint256 durationInSeconds
    ) public {
        require(bytes(slug).length > 0, "Slug is required");
        require(bytes(title).length > 0, "Title is required");
        require(bytes(description).length > 0, "Description is required");
        require(benefactor != address(0), "Invalid benefactor address");
        require(goal > 0, "Goal should be greater than 0");
        require(durationInSeconds > 0, "Duration should be greater than 0");

        Campaign storage newCampaign = allCampaigns[slug];

        // Ensure the slug is unique by checking if the campaign's deadline is 0 (not initialized).
        require(newCampaign.deadline == 0, "Campaign with this slug already exists");

        newCampaign.title = title;
        newCampaign.slug = slug;
        newCampaign.description = description;
        newCampaign.benefactor = benefactor;
        newCampaign.goal = goal;
        newCampaign.deadline = block.timestamp + durationInSeconds;
        newCampaign.isActive = true;

        emit CampaignCreated(slug, title, benefactor, goal, newCampaign.deadline);
    }

    function getCampaignDetails(string memory slug) public view returns (Campaign memory) {
        return allCampaigns[slug];
    }

    function donateToCampaign(string memory campaignSlug) public payable isValidCampaign(campaignSlug) nonReentrant {
        Campaign storage campaign = allCampaigns[campaignSlug];

        uint256 amountRaised = campaign.amountRaised + msg.value;

        campaign.amountRaised = amountRaised;

        if (amountRaised >= campaign.goal) {
            (bool success,) = address(campaign.benefactor).call{value: campaign.amountRaised}("");

            require(success, "Transfer failed");

            campaign.isActive = false;
        }

        emit DonationReceived(campaignSlug, msg.sender, msg.value);
    }

    function endCampaign(string memory campaignSlug) public isValidCampaign(campaignSlug) nonReentrant {
        Campaign storage campaign = allCampaigns[campaignSlug];

        if (block.timestamp < campaign.deadline) {
            revert("Campaign is still active");
        }

        campaign.isActive = false;

        (bool success,) = address(campaign.benefactor).call{value: campaign.amountRaised}("");

        require(success, "Transfer failed");

        emit CampaignEnded(campaignSlug, campaign.amountRaised);
    }
}
