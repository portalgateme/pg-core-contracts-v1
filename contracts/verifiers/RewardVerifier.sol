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
        vk.alfa1 = Pairing.G1Point(uint256(18386512748080970183808781530282041178225354343813969265042777463431779294780), uint256(12654630153701862527074159531338334317644019988083500898008536109613804611067));
        vk.beta2 = Pairing.G2Point([uint256(15199237716800135712674393587658616610286743868298507418521381207918494120329), uint256(19223976172429468600105692762482560547355026792076544962652390226502207764691)], [uint256(2493599718268133237133642890185046359153275815832064921360542685038447962894), uint256(5781125939070362383843099589503227713048503087199928576998237627981731967705)]);
        vk.gamma2 = Pairing.G2Point([uint256(21702835694940882038685754541036578375747895974974578076869722215858116418372), uint256(12455278085818738221695041351247195509482231333549516702104065771781407938009)], [uint256(11330619420949130820312080860151433315098335641101558219095691758876463084565), uint256(9972777092654719479974072935080705306795432874482945781530948395998819101676)]);
        vk.delta2 = Pairing.G2Point([uint256(9345906695578386282922912132861435441058993574886970136372622041717220697180), uint256(18862227723400456235843153890037675061963708183427989828975605626310229331945)], [uint256(12288679770865001585784245917679362875408183422970583360612197323202272714466), uint256(13871096052068908172447698472564455572872444960279428258044365174532388815505)]);
        vk.IC[0] = Pairing.G1Point(uint256(8008110709302646104504581745150824173386248410643363813237774789667426021083), uint256(2156808134357546300315525816120445754394431516440349023613476787717431943429));
        vk.IC[1] = Pairing.G1Point(uint256(925765510512156472658968443388398529981853043452984512930258222302197138545), uint256(10711095049215201384684149225000148131717870179899504232233006667869585416622));
        vk.IC[2] = Pairing.G1Point(uint256(17981606618208676794974566207841967682670730107376934574928603410228302831967), uint256(7549993164439009101161541034630930170753022692711353863397530069361846978268));
        vk.IC[3] = Pairing.G1Point(uint256(14705655747850532372783317186220685168074092728048718738391294749552643310060), uint256(2195661853310200670786672474132776752713072342252181993500827874069633381300));
        vk.IC[4] = Pairing.G1Point(uint256(4845431861644641372207893948792756634748968646999523200476467311995262290396), uint256(3362107028250351041253587125542697928170800637345315006150487444722905168264));
        vk.IC[5] = Pairing.G1Point(uint256(9631694801061122406024201520756703234644740669919863031866871177636822855191), uint256(4024104347359941045269924746549260495120220943752478542324411200432990521269));
        vk.IC[6] = Pairing.G1Point(uint256(12048955819362734061816565853848793592781895272686362355172844730022528428310), uint256(6707652283029393974682056924488703125241130298630024876096485318454570816366));
        vk.IC[7] = Pairing.G1Point(uint256(17279127641374421916056105488360728407192577629896089486791846982093806526645), uint256(9345732219694311174421990163937255206047415052728865399576135934452800672780));
        vk.IC[8] = Pairing.G1Point(uint256(15458033594478293780950368446668778564641369407532104176801715071066804842782), uint256(6378113981782743682173764536108244706518419505030083778571666713726286301201));
        vk.IC[9] = Pairing.G1Point(uint256(13737613138498415925890612170949704377963397584851929747532311453780812794369), uint256(16219964839897024124984674483060062551956678356039197990020813128746228025201));
        vk.IC[10] = Pairing.G1Point(uint256(15298792622945898802544094128073644642257750074944942039214975681266914480594), uint256(17197636667371582268973194414204926906282900277667793220642545902157646194181));
        vk.IC[11] = Pairing.G1Point(uint256(18169460693244589848549198430771436086800446561846707067051253331137754431953), uint256(5913315904905141762813598472705706770114199942542733758696674542825373935607));
        vk.IC[12] = Pairing.G1Point(uint256(19082484087188054823418102931063592296739890632221292654329024763547054402643), uint256(19942258207861169167564676630294629387374918226329850104517193177345609792475));

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

