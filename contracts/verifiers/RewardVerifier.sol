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

contract RewardVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[13] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(12358386019398659769650998102776163760887092095206633230583351736858251645761), uint256(7726917623245141873313558353039634693943100424731678711458504896118593114633));
        vk.beta2 = Pairing.G2Point([uint256(3424084485489656417317333748627314649725927928504065774725496628756609794611), uint256(13720571624854434960178603861514299757807127396223254173610762146136922541573)], [uint256(12900295486909815092031646389142112823337104347074666309940891504038244579193), uint256(7207883899897984568156569893781336233947363902242229733625812927127658434918)]);
        vk.gamma2 = Pairing.G2Point([uint256(12655268640676012615696062674688219242297659554709470328768995068217192086005), uint256(20735958597121000799471303146854252442013645494123077484334180537395871380721)], [uint256(8963773584097224138301802526807342018791245482060586153536986678755302010726), uint256(10204460235705444557097178583788196245102222390974602887791777633751213955411)]);
        vk.delta2 = Pairing.G2Point([uint256(12982138998712288114914856967429406355230486462849365936765087417337857548452), uint256(3056553744702686604346836628030577320344074423328576072893305889362175249783)], [uint256(20729404768501327186141906644290169766445245377589568695375149917046811811302), uint256(1399121076344059777299029905134151377679873951821569394137156378228972702821)]);
        vk.IC[0] = Pairing.G1Point(uint256(19235346268206550478639002449839298042275540705026293699773137816078205192846), uint256(21044235828371041598507339839592714327583678901417363936971848078874086650880));
        vk.IC[1] = Pairing.G1Point(uint256(14284750696369800702992294907247599438545715347647348424050036294188793907609), uint256(20016339560872238891220738313207135364846656370467027795694300230977295788156));
        vk.IC[2] = Pairing.G1Point(uint256(14608805576846941881293608624464581464019501023793509953490774179960859560431), uint256(21310167845243348433432833235620491444451082451130516203968825682614265004210));
        vk.IC[3] = Pairing.G1Point(uint256(8374101873315971246694148891346494279655396497364690287271928942759333787383), uint256(15483604858878740189134623660858072803140143635181220565838949343339359997128));
        vk.IC[4] = Pairing.G1Point(uint256(19548238024959352072754018453120893627923790050263764385119948043960281719700), uint256(20060086181183709171450610656198781254062125037730957294507965335409712606739));
        vk.IC[5] = Pairing.G1Point(uint256(175932616081420032109809147800927777163118117981464599177787873970938448626), uint256(19903314375669773116400137127873767637809853285590699085217169161939296561306));
        vk.IC[6] = Pairing.G1Point(uint256(4479971027176182374582501300966389118710672273718205952517592509483178583957), uint256(7775006531367538580134673298990339043245855160320084665618812923163518526261));
        vk.IC[7] = Pairing.G1Point(uint256(9805643301932453389803150364366732891050129808805250916726106601421919972549), uint256(16786960390635490363707604045123815853672303722103097164707323459093220332286));
        vk.IC[8] = Pairing.G1Point(uint256(15917790635550593617743593338546954116691930786998151389340897590064791372705), uint256(6573289596745239550636608259810199025972776376939722137880874472163673974912));
        vk.IC[9] = Pairing.G1Point(uint256(9228498769411796829040206670157170121114679416900702241523281157931338214509), uint256(17025973648103294452966962228401512523224164603101216646605873137093219080540));
        vk.IC[10] = Pairing.G1Point(uint256(19877772417896059153257718386515221832342498118440205164980275021276134215033), uint256(14778278978202887406522444220871077293124717796679536632555208901058406766036));
        vk.IC[11] = Pairing.G1Point(uint256(18999308747767501396821286902821149985787094704127106947669930229219461038246), uint256(13504453364639204371016189382158968173937872818091326497765956994026214473273));
        vk.IC[12] = Pairing.G1Point(uint256(8451158261388993742050586345538801033263527197066199331748997057617956536688), uint256(19742555846326950037450701520591069351917030233433831336040041480470096448700));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[12] memory input
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

