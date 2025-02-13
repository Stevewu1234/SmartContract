//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NetSepio.sol";
import "./INetStatus.sol";

contract NetReview is NetSepio {
    
    struct WebSiteReview {
        address reviewer;
        string siteUri;
        bytes metaDataIPFSPath;
    }

    // bytes32 website name.
    mapping (bytes32 => mapping(uint256 => WebSiteReview)) private reviewStatus;

    mapping (address => mapping(bytes32 => bool)) private userReviewed;

    INetStatus private netStatus;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseuri,
        address netStatusAddress
    ) NetSepio(_name, _symbol, _baseuri) {
        netStatus = INetStatus(netStatus);
    }


    /** ========== public view function ========== */
    function checkReviewed(address reviewer, bytes32 siteName) public view returns (bool) {
        return userReviewed[reviewer][siteName];
    }

    /** ========== public mutative functions ========== */

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     */
    function createReview(
        string memory _siteName,
        bytes32 _siteUri, 
        bytes _IPFSPathHash,
        string memory _tag,
        string memory _siteType,
        string memory _siteSafety
    ) public {
        
        require(!checkReviewed(_msgSender(), _siteName), "Sorry, you are only able to review once");

        uint256 tokenId = _netMint(_IPFSPathHash);
        _setWebSiteReview(_msgSender(), _siteUri, tokenId, _siteName, _IPFSPathHash);

        netStatus.addSiteDetails(_siteName, _tag, _siteType, _siteSafety, _msgSender());

        emit reviewCreated(_msgSender(), tokenId, _siteName, block.timestamp);
    }

    /**
    * @dev Updates the metadata of a specified token. Writes `newMetadataHash` into storage
    * of `tokenId`.
    *
    * @param tokenId The token to write metadata to.
    * @param newMetadataHash The metadata to be written to the token.
    *
    * Emits a `ReviewUpdate` event.
    */
    function updateReview(bytes32 memory _siteName, uint256 tokenId, string memory newMetadataIPFSPath) public {
        require(checkReviewed(_msgSender(), _siteName), "Sorry, you must review firstly");

        reviewStatus[_siteName][tokenId].metaDataIPFSPath = newMetadataIPFSPath;

        emit reviewUpdated(_msgSender(), tokenId, _siteName, block.timestamp);
    }

    /**
     * @dev Destroys (Burns) an existing `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function deleteReview(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NetSepio: caller is not owner nor approved to delete review");
        
        
        // destroy (burn) the token.
        burn(tokenId);
        emit reviewDeleted(_msgSender(), tokenId, block.timestamp);
    }

    /** ========== external view functions ========== */

    /**
    * @dev Reads the metadata of a specified token. Returns the current data in
    * storage of `tokenId`.
    *
    * @param tokenId The token to read the data off.
    *
    * @return A string representing the current metadataHash mapped with the tokenId.
    */
    function readMetadata(bytes32 _siteName, uint256 tokenId) external view returns (string memory) {
        return reviewStatus[_siteName][tokenId].metaDataIPFSPath;
    }


    function reviewDetails(bytes32 _siteName, uint256 tokenId) external view returns (
        address reviewer_,
        string siteUri_,
        bytes metaDataIPFSPath_
    ) {
        WebSiteReview memory review = reviewStatus[_siteName][tokenId];

        reviewer_ = review.reviewer;
        siteUri_ = review.siteUri;
        metaDataIPFSPath_ = review.metaDataIPFSPath;
    }

    /** ========== internal mutative functions ========== */

    function _setWebSiteReview(
            address _reviewer,
            string memory _webSiteUri, 
            uint256 tokenId,
            bytes32 _siteName,
            bytes _metaDataHashIPFSPath
        ) internal {

            WebSiteReview memory review;

            review.reviewer = _reviewer;
            review.siteUri = _webSiteUri;
            review.metaDataHash = _metaDataHash;

            reviewStatus[_siteName][tokenId] = review;
            userReviewed[_reviewer][_siteName] = true;
    }

    /** ========== event ========== */
    event reviewCreated(address indexed reviewer, uint256 indexed tokenId, bytes32 siteName, uint256 createdTime);

    event reviewUpdated(address indexed reviewer, uint256 indexed tokenid, bytes32 siteName, string newMetadataIPFSPath, uint256 updatedTime);

    event reviewDeleted(address indexed reviewer, uint256 indexed tokenId, uint256 deletedTime);
}