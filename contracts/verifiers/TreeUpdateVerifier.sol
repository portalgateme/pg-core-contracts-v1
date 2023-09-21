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

contract TreeUpdateVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[5] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(17132756534831848301689641990833703638617458056443929224751048942777666614541), uint256(19008879453057450139602262680406039018411841171181194290310757724975574994489));
        vk.beta2 = Pairing.G2Point([uint256(435304167485403401483672793634494780168201186217379920744037116970483374875), uint256(9027846451316529550551210599381437758614830474269236248281285293799526098343)], [uint256(19349385513153732120447101495142647374825505141401747287599603304249941169445), uint256(15662358168600582247416868892992153355082669520533182339239962785958666270720)]);
        vk.gamma2 = Pairing.G2Point([uint256(3650654117538507006084019329549922226202594632616794194599018149508364674957), uint256(12280911507962424252937039601064449796421730835995065283639388695214858113234)], [uint256(17017501773411339687480953419163692032488262067762025884471497814604817799742), uint256(17762925737507970336716755796404767416823316134592084811660714484773615773624)]);
        vk.delta2 = Pairing.G2Point([uint256(11882576555271371828304068563974958177756475642084096241095329199734932235542), uint256(11547023723965973746595842694238731157144164933673076995203497963012154418064)], [uint256(12643239452298248461969822791117051485068116295107818633404339765534176220571), uint256(11316245442728039639429001869727665314618807665701393165109847339236062288834)]);
        vk.IC[0] = Pairing.G1Point(uint256(16928773785440119154089769854005361215205835724322279179925579313648940838786), uint256(13649762916466752861885585459552496869404061993452895902407719213094027671360));
        vk.IC[1] = Pairing.G1Point(uint256(10774466173635888825109709573716581877556665108379017810285559982986318476260), uint256(9633133119509335072444261492962672338563163668037702652415077516261212541897));
        vk.IC[2] = Pairing.G1Point(uint256(20835431785747870095949277694914914479656803720289198736360069178546654618479), uint256(10101480741937085966340956694837696194957443873421440820964654109011689970358));
        vk.IC[3] = Pairing.G1Point(uint256(6050189477296687059274517344458322232120934431305812963294200295644485812804), uint256(19809096351743459190322624243825114504626686397115152314426771008702740497823));
        vk.IC[4] = Pairing.G1Point(uint256(17041025672398975198038648966903527113413528622521152521792372547526784443720), uint256(5597910110889325690160570836032301327707016003478239654254877449650918028171));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[4] memory input
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

