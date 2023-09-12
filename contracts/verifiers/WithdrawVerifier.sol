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
        vk.alfa1 = Pairing.G1Point(uint256(9615181204190616497881660787173411614480177568182306791365483787615210939756), uint256(10172825638710559319968314582612344383130999089862538431743755472030704236318));
        vk.beta2 = Pairing.G2Point([uint256(19469855242075390281455190522069470431984353296259406663134274642655430406534), uint256(16890679895087179622943944325310291990605262520791111629135391070054709212113)], [uint256(7204072937721739367110030307563199581248903512230970331928190432377316287285), uint256(200551350283590286680275116076409449310705367474496643741083129398617932478)]);
        vk.gamma2 = Pairing.G2Point([uint256(19729634600307982026895151874753307749627230581801577827442318210511868887218), uint256(18422002743668399331205751554130289180439843683486376945147503081905500763783)], [uint256(3817863247305222768834844432622218868455615987283843331239002462691551101891), uint256(12873025343073469609986694056452633276237039026300934947571676053304929147501)]);
        vk.delta2 = Pairing.G2Point([uint256(1482801814983209510235352351267391210909358518936994590761076060140046293878), uint256(5139314354876186354603000415309007354965276238019667252733818608478784895191)], [uint256(17897826949459343120881767073323249401620980227565228715646578229684706786136), uint256(17729295066129233184980796808716555766616519549755248650918554801557434255698)]);
        vk.IC[0] = Pairing.G1Point(uint256(125859103767759884504714161408136034487278817433393764649033453484519483485), uint256(3655803420493511154640139483955799958211158121058292739817517537052748524064));
        vk.IC[1] = Pairing.G1Point(uint256(19957263842847324637590434465300398979683252844155161209988637423473384189829), uint256(12462656660793656504500751604569995735330160783709571178890550316814326609345));
        vk.IC[2] = Pairing.G1Point(uint256(14678097399109302537706422826388329659584271439505774267757676462455655443756), uint256(2356741018105707415812533003341086657220677262489756640915100655164863366313));
        vk.IC[3] = Pairing.G1Point(uint256(3660124757896335305478617355365414974183830422843488140579581676130623964337), uint256(8046977912820482727949302583990368726389562923891624053154878159150146276212));
        vk.IC[4] = Pairing.G1Point(uint256(21652276972889466216478986490642528944787989796599386873534120301165781780542), uint256(16366937056587528857140775116071882402760721021349162187917954358349663104346));
        vk.IC[5] = Pairing.G1Point(uint256(20499605875355067545280143064487057713669046316480735670450732582270754748269), uint256(3938330210049772009280910912268827509599736720561341216895030851293632521374));
        vk.IC[6] = Pairing.G1Point(uint256(4162193699160189352020036437644467796889717401454216930577599913371524583937), uint256(1797987694245602197775286662186527494531490206689448218193577197289741050773));
        vk.IC[7] = Pairing.G1Point(uint256(14938284945996763764057589054531873670740520474707101235693883372348554457387), uint256(10552906232416813063630102050236384493417317699160166302158018581656871900939));

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

