// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return r the sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input = [
            p1.X, p1.Y,
            p2.X, p2.Y
        ];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
     *         points p.
     */
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        uint256[24] memory input = [
            a1.X, a1.Y, a2.X[0], a2.X[1], a2.Y[0], a2.Y[1],
            b1.X, b1.Y, b2.X[0], b2.X[1], b2.Y[0], b2.Y[1],
            c1.X, c1.Y, c2.X[0], c2.X[1], c2.Y[0], c2.Y[1],
            d1.X, d1.Y, d2.X[0], d2.X[1], d2.Y[0], d2.Y[1]
        ];
        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, mul(24, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract WithdrawVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[8] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(20470538624038857487064074491341520183800653484387633547534252526264117886173), uint256(17151933215328736042788465732093823902413326566071286960731206598944333800662));
        vk.beta2 = Pairing.G2Point([uint256(6610527693261380170851771788612167847992998587198537966127657447434930676363), uint256(6388656687979976069207076135669856708399271424165544509183056859886648576353)], [uint256(4134690587329136429730768098450647757844461918831926033977379046702801357151), uint256(7101420947608908463209728959475049782051435786036548536407246758671065270779)]);
        vk.gamma2 = Pairing.G2Point([uint256(21072354819006283380757188947256170528204137311793807664788650385167458101703), uint256(20628357150167269965342756415866466547367927917533409308834349679577280421429)], [uint256(3240720603416771949425440023348030290937265597986267665484895765301357773802), uint256(11280156898829237430198526990460726383365201394832899366722723273851922679013)]);
        vk.delta2 = Pairing.G2Point([uint256(11395147944957412481601956226526424023788374838605132675901305049515414923547), uint256(11011352963676154228106806091753571381953556693938050044306491931345387161933)], [uint256(11166851996583738387158668211209029258671763405058622236490262300402826002185), uint256(16955192374894378363757857532331154142436548863649172576491503403441472475700)]);
        vk.IC[0] = Pairing.G1Point(uint256(8307082651131665130204107688746093265967869053852466792203739112522478969478), uint256(16843182562184497773109121691662224305904606270237202595202098772481688336223));
        vk.IC[1] = Pairing.G1Point(uint256(20984072186341493032219542505815649399686034529665563795498118563447081346983), uint256(15007749331345998244897962082089030747330168760193872547422012168889855231350));
        vk.IC[2] = Pairing.G1Point(uint256(21276926610225114452436572811353881445472731492594807806277375626416279755180), uint256(5194406258366364023761573897299860431995279175442583968231220564589949651657));
        vk.IC[3] = Pairing.G1Point(uint256(20697963873480860663468295196681795562379495343457697134813593373649350766560), uint256(1443409538146646129101806911086923993176893466946482148110633255430941729468));
        vk.IC[4] = Pairing.G1Point(uint256(6179426872037482970911909878753636750124153726053344343547019851182415853508), uint256(21404660652870961688440132293608803016298977624629269812029749050487090869471));
        vk.IC[5] = Pairing.G1Point(uint256(15902964338479663704291856487597705236341588166809144855120497329753206857631), uint256(14379618847707819681271397004168839802910450458822813252490409290533099359078));
        vk.IC[6] = Pairing.G1Point(uint256(440585354276021134033750473869791217385547443434709957547563798908129059803), uint256(4985322076159357709863081864422334604014359021591657906097876548818399794350));
        vk.IC[7] = Pairing.G1Point(uint256(3574987130142368981861903877384200443707480283833765809934459232383023475784), uint256(859946200239743125300234684574285424524559532262373891285002166031244573121));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[7] memory input
    ) public view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        for (uint8 i = 0; i < p.length; i++) {
            // Make sure that each element in the proof is less than the prime q
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Pairing.G1Point memory proofA = Pairing.G1Point(p[0], p[1]);
        Pairing.G2Point memory proofB = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(p[6], p[7]);

        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = vk.IC[0];
        for (uint256 i = 0; i < input.length; i++) {
            // Make sure that every input is less than the snark scalar field
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-input-gte-snark-scalar-field");
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.IC[i + 1], input[i]));
        }

        return Pairing.pairing(
            Pairing.negate(proofA),
            proofB,
            vk.alfa1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proofC,
            vk.delta2
        );
    }
}

