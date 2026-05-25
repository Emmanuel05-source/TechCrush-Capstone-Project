// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {UICertiVerification} from "../src/UICertiVerification.sol";

contract UICertiVerificationTest is Test {
    UICertiVerification certContract;

    address owner = address(1);
    address student = address(2);
    address attacker = address(3);

    function setUp() public {
        vm.prank(owner);
        certContract = new UICertiVerification(owner);
    }

    //                  ISSUE CERTIFICATE TEST
    function testIssueCertificate() public {
        vm.prank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        assertEq(certContract.ownerOf(1), student);
        bool valid = certContract.isCertificateValid(1);
        assertEq(valid, true);
    }

    //              UNAUTHORIZED ISSUE TEST
    function testNonOwnerCannotIssueCertificate() public {
        vm.prank(attacker);

        // Assert specific OpenZeppelin or custom error instead of empty revert
        vm.expectRevert();
        certContract.issueCertificate(
            student,
            "Fake Student",
            "UI/000/000",
            "Fake Degree",
            "Fake Department",
            "Fake Faculty",
            "1.00/5.00",
            "FAKE-CERT",
            "Third Class",
            2025,
            "ipfs://fake-uri"
        );
    }

    //                    REVOKE TEST
    function testRevokeCertificate() public {
        vm.startPrank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        certContract.revokeCertificate(1);
        vm.stopPrank();

        bool valid = certContract.isCertificateValid(1);
        assertEq(valid, false);
    }

    //              SOULBOUND TRANSFER TEST
    function testSoulboundTransferFails() public {
        vm.prank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        vm.prank(student);
        // Explicitly expect our custom Soulbound error
        vm.expectRevert(
            UICertiVerification.UICertiVerification__SoulboundToken.selector
        );
        certContract.transferFrom(student, attacker, 1);
    }

    //            DUPLICATE CERTIFICATE TEST
    function testDuplicateCertificateFails() public {
        vm.startPrank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        // Explicitly expect the certificate collision revert
        vm.expectRevert(
            UICertiVerification
                .UICertiVerification__CertificateAlreadyExists
                .selector
        );
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );
        vm.stopPrank();
    }

    //              VERIFY CERTIFICATE TEST
    function testVerifyCertificate() public {
        vm.prank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        // CORRECTION: Destructure according to our optimized struct return signature
        (
            UICertiVerification.Certificate memory cert,
            address tokenOwner
        ) = certContract.verifyCertificate(1);

        assertEq(cert.studentName, "Emmanuel Dada");
        assertEq(cert.revoked, false);
        assertEq(tokenOwner, student);
    }

    //              TOTAL CERTIFICATE TEST
    function testTotalCertificatesIssued() public {
        vm.prank(owner);
        certContract.issueCertificate(
            student,
            "Emmanuel Dada",
            "UI/2020/123",
            "B.Sc Computer Science",
            "Computer Science",
            "Faculty of Science",
            "4.87/5.00",
            "UI-CERT-2025-001",
            "First Class",
            2025,
            "ipfs://sample-uri"
        );

        uint256 total = certContract.totalCertificatesIssued();
        assertEq(total, 1);
    }
}
