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

contract Verifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[4] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(18992445984182996440490650876722529785422381241984212487309053250777820819262), uint256(15225849748130465432707417534527870653615869805981219150756211895687811573424));
        vk.beta2 = Pairing.G2Point([uint256(20895689014026939363049327279374608296413272438796632430606640111728510294641), uint256(18405266433860021895425150929928993526561153608532109362889917832872130946424)], [uint256(3908367051841070557524982088014658021080743305413682253092091075349308344177), uint256(15529943839269667965457973032653672181035797994130889633674970412749141455020)]);
        vk.gamma2 = Pairing.G2Point([uint256(12561183145337305996512294139393054305706389528645998088188351081551188007650), uint256(502941844498272142465905103383759523928147865471401818728170596908643982428)], [uint256(5869279028636121682600204081747940812550652594159938179430304723669534248744), uint256(15336789012635521684036465771439541501795702462242210013320564663961214008302)]);
        vk.delta2 = Pairing.G2Point([uint256(6719879136622290361600882067991416922277284151497753755841064572323138261385), uint256(1392288951856844839694323453456591861650776414901696808030744758283383850556)], [uint256(4627825906536402313558965721414656405440109651213685214023317102607432320255), uint256(3998888475015038094509172645724344281760041776098683473976965140865507482480)]);
        vk.IC[0] = Pairing.G1Point(uint256(4469393433865667843043619787328962915225746394128709809597207581295154642434), uint256(13855241465832998416983272309259215635803220078238170856683000032504268033818));
        vk.IC[1] = Pairing.G1Point(uint256(12923089538622612876466503388583828149938447768027852728414715166559558556234), uint256(3480266045149150252729040378530153731731330921746716753649233606769540850191));
        vk.IC[2] = Pairing.G1Point(uint256(4523225139348991672748512812711488740630288183903333982130825018849291837844), uint256(11265485459149136937998049685205623900200557047327408334494112671359696993596));
        vk.IC[3] = Pairing.G1Point(uint256(8049217630020481861510547643662350592883290659445856539096676683073281622436), uint256(323936634104477066132133826144264053664153247588890063946117910933194108829));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[3] memory input
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

