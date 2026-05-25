//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

 * UICertiVerification

 * University of Ibadan Soulbound Certificate Verification System
 *
 * Features:
 * - Soulbound ERC721 Certificates
 * - Certificate Issuance
 * - Public Verification
 * - Revocation System
 * - IPFS Metadata Support
 * - Duplicate Certificate Prevention
 * - OpenZeppelin Integration

 */

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract UICertiVerification is ERC721, Ownable {
    //                           VARIABLES
    string public constant UNIVERSITY_NAME = "University of Ibadan";
    uint256 private s_tokenCounter;

    //                           STRUCTS
    struct Certificate {
        string studentName;
        string matricNumber;
        string degree;
        string department;
        string faculty;
        string cgpa;
        string certificateNumber;
        string classOfDegree;
        uint256 graduationYear;
        uint256 issueDate;
        bool revoked;
        string metadataURI;
    }

    //                           MAPPINGS
    mapping(uint256 => Certificate) private s_certificates;
    mapping(bytes32 => bool) private s_certificateExists;

    //                           EVENTS
    event CertificateIssued(
        uint256 indexed tokenId,
        address indexed student,
        string matricNumber
    );
    event CertificateRevoked(uint256 indexed tokenId);

    //                           ERRORS
    error UICertiVerification__CertificateAlreadyExists();
    error UICertiVerification__CertificateDoesNotExist();
    error UICertiVerification__CertificateAlreadyRevoked();
    error UICertiVerification__SoulboundToken();
    error UICertiVerification__InvalidAddress();

    constructor(
        address initialOwner
    ) ERC721("UICertiVerification", "UICERT") Ownable(initialOwner) {
        s_tokenCounter = 1;
    }

    //                    ISSUE CERTIFICATE
    function issueCertificate(
        address student,
        string memory studentName,
        string memory matricNumber,
        string memory degree,
        string memory department,
        string memory faculty,
        string memory cgpa,
        string memory certificateNumber,
        string memory classOfDegree,
        uint256 graduationYear,
        string memory metadataURI
    ) external onlyOwner {
        if (student == address(0)) {
            revert UICertiVerification__InvalidAddress();
        }

        bytes32 certificateHash = keccak256(
            abi.encodePacked(matricNumber, degree, graduationYear)
        );

        if (s_certificateExists[certificateHash]) {
            revert UICertiVerification__CertificateAlreadyExists();
        }

        uint256 tokenId = s_tokenCounter;
        _safeMint(student, tokenId);

        s_certificates[tokenId] = Certificate({
            studentName: studentName,
            matricNumber: matricNumber,
            degree: degree,
            department: department,
            faculty: faculty,
            cgpa: cgpa,
            certificateNumber: certificateNumber,
            classOfDegree: classOfDegree,
            graduationYear: graduationYear,
            issueDate: block.timestamp,
            revoked: false,
            metadataURI: metadataURI
        });

        s_certificateExists[certificateHash] = true;
        emit CertificateIssued(tokenId, student, matricNumber);
        s_tokenCounter++;
    }

    //                    REVOKE CERTIFICATE
    function revokeCertificate(uint256 tokenId) external onlyOwner {
        if (_ownerOf(tokenId) == address(0)) {
            revert UICertiVerification__CertificateDoesNotExist();
        }

        Certificate storage cert = s_certificates[tokenId];
        if (cert.revoked) {
            revert UICertiVerification__CertificateAlreadyRevoked();
        }

        cert.revoked = true;
        emit CertificateRevoked(tokenId);
    }

    //                    VERIFY CERTIFICATE
    function verifyCertificate(
        uint256 tokenId
    ) external view returns (Certificate memory cert, address tokenOwner) {
        tokenOwner = _ownerOf(tokenId);
        if (tokenOwner == address(0)) {
            revert UICertiVerification__CertificateDoesNotExist();
        }

        cert = s_certificates[tokenId];
    }

    //                    GET CERTIFICATE DETAILS
    function getCertificate(
        uint256 tokenId
    ) external view returns (Certificate memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert UICertiVerification__CertificateDoesNotExist();
        }
        return s_certificates[tokenId];
    }

    //                   CHECK CERTIFICATE VALIDITY
    function isCertificateValid(uint256 tokenId) external view returns (bool) {
        if (_ownerOf(tokenId) == address(0)) {
            return false;
        }
        return !s_certificates[tokenId].revoked;
    }

    //                  TOKEN URI
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert UICertiVerification__CertificateDoesNotExist();
        }
        return s_certificates[tokenId].metadataURI;
    }

    //                 TOTAL CERTIFICATES ISSUED
    function totalCertificatesIssued() external view returns (uint256) {
        return s_tokenCounter - 1;
    }

    //                    SOULBOUND LOGIC

    /**
     * @dev Enforces Soulbound behavior by intercepting all transfers.
     * Allows minting (from == address(0)) but reverts on any transfer.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // If it's not a mint (from != 0) and not a burn (to != 0), it's a transfer.
        if (from != address(0) && to != address(0)) {
            revert UICertiVerification__SoulboundToken();
        }

        return super._update(to, tokenId, auth);
    }

    // You can keep these to disable the UI buttons on marketplaces like OpenSea
    function approve(address, uint256) public pure override {
        revert UICertiVerification__SoulboundToken();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert UICertiVerification__SoulboundToken();
    }
}
