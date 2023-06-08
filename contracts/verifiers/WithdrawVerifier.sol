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
        vk.alfa1 = Pairing.G1Point(uint256(11813195599117868692718921039257601522104900295886670455781143885718057574958), uint256(20717234195802319960872169427379680873758130354235976240262430663151857580091));
        vk.beta2 = Pairing.G2Point([uint256(12677941052677084096140899617980105153401346294971345160415122510801321760178), uint256(8695393036368681387928331983412980298665193311623663612160324794535637465742)], [uint256(4556492003314371291066690675142672870190031384693582439042196220167415948202), uint256(21352853843784065170211631458304422797796841555241530653471978564541046618234)]);
        vk.gamma2 = Pairing.G2Point([uint256(15391343471335128157685466384198797761215228929218774222640332553088751509389), uint256(3735804362141249111584353105080473490718664558929901436707462662123140603855)], [uint256(18469189133766828749256446173900176110374115905169008811489460217134414105067), uint256(13076126612524040842741012085410238258427959620149315434604834262869253853725)]);
        vk.delta2 = Pairing.G2Point([uint256(15714958864187884968634908315006589101162919074415258185008784712834467288163), uint256(3999184936668005120044843376926110360169150166134765810567168054736792687823)], [uint256(17403957741910670753629844282039752987762834387900984600080964437824686652313), uint256(5749912835526189870354310618843964178039129734296169721257265275686704111761)]);
        vk.IC[0] = Pairing.G1Point(uint256(3398377635676649412985937706615805608857506849075859144512867313059894684182), uint256(19490724824840674885445159169611518578849508498355371422341582629517131790356));
        vk.IC[1] = Pairing.G1Point(uint256(3882683493167970023836458970822705246681306853862787668934526220651007886273), uint256(5684869405452777491573124096193742718187101359099907030258698944255375549730));
        vk.IC[2] = Pairing.G1Point(uint256(4607483231631277591557014148486371890316097113809534090995325646491518311687), uint256(19603192877931829617281684447035020709203270214881197497330911838856020714754));
        vk.IC[3] = Pairing.G1Point(uint256(16683874598934791900101246965753296414237943263404264498070180328260429112911), uint256(1315173717428258534000456582725619693585261398421291358140604163770163290817));
        vk.IC[4] = Pairing.G1Point(uint256(21413785436704303506546582707198253388595690085777277090316524037618325037219), uint256(9744730472025254855221341524033157718892673907649971388975306355506202678319));
        vk.IC[5] = Pairing.G1Point(uint256(11886294186517926006582184363372548144618466365914965354647425238603436130939), uint256(18360268687919251317467854318333683759696803119657609439264844369149157307011));
        vk.IC[6] = Pairing.G1Point(uint256(1384826431524672889600803840917436208647952999489913193942564735011674636501), uint256(2670574633484613092866093704280936341407456946710978550091814353965778586601));
        vk.IC[7] = Pairing.G1Point(uint256(16677998408771086150990521795014081035189638675423072772769494246389055619479), uint256(13808434869432361391266076387603043667750987607142165488531045574501660960596));

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

