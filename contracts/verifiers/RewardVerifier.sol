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
        vk.alfa1 = Pairing.G1Point(uint256(9016853131130524280600013457650441868326993889332624615373261560582301639331), uint256(21652679118988487859361010119355132007789267145592297860793646240578634923266));
        vk.beta2 = Pairing.G2Point([uint256(9211269180003816010421781698176309051268872761644056799477765384924782432313), uint256(7238949485834373537967993990165534438143225748106218192824608548749352256390)], [uint256(10710125212563030161053433689997261717013313394527547145514002508245740489685), uint256(21322466284482026391348765702688839389074076321253937105456216774509302001157)]);
        vk.gamma2 = Pairing.G2Point([uint256(8628480591786769823793131146381134187265468213191978844421339217910338365963), uint256(14373611499443317122240573976123034363617018758484101063959573068909222860196)], [uint256(14997297531551520970562729946570369575310546129989689810819262321579534319850), uint256(21671752469522982606961419901301608162755539312343972549282780615557179097910)]);
        vk.delta2 = Pairing.G2Point([uint256(13574760911025976629984980423465520354729066273397640321078839082180448991233), uint256(10873608073353648307187206891179240466103246508505903616588670140655037993566)], [uint256(7733146097897412866626629522663024875140387666505583760768820451202976753473), uint256(7980417134450464821114388697695336238514767320802737397082537168699252750045)]);
        vk.IC[0] = Pairing.G1Point(uint256(19663282859429747737472349683220765048133081417274726529163710169011378560496), uint256(3287785119258962747661413311549989086309777312733183418121400647592955102766));
        vk.IC[1] = Pairing.G1Point(uint256(16022170558682867007338609466472610604956024507746043756008727949450688448736), uint256(8199168629671949800051747213661206008888949086310742605937254059127142064228));
        vk.IC[2] = Pairing.G1Point(uint256(4343812558978130991650538678156261630313190259567792744332715927967946964542), uint256(5305486263461447709786775669796467512316676298533309600256490591538020441253));
        vk.IC[3] = Pairing.G1Point(uint256(19652677556104832322950539251243952316710685327010576989079943249483818888967), uint256(6864429151102354784027401849859164706805774530849016672821614748595343711567));
        vk.IC[4] = Pairing.G1Point(uint256(18969066534111601423769045389232751297061065944095450700523423197897057972174), uint256(17601604307262544607025703497199373548561891905502773594860004786574887990592));
        vk.IC[5] = Pairing.G1Point(uint256(6666366747309751556666122262858909279952419706958962953798293216584065859141), uint256(9996671397288617450596037586817855018252853068587235229795711788578698860052));
        vk.IC[6] = Pairing.G1Point(uint256(19880127648972196326603200382945253829281439223321587200057798575051275228918), uint256(2732698149515388430389534858148620835435292957829362146949228848616070264042));
        vk.IC[7] = Pairing.G1Point(uint256(19631732139022619174389576441402699528119155425246887085232531740065007436557), uint256(17316914061514843900123469213788875804972782676302810916394403716682833893386));
        vk.IC[8] = Pairing.G1Point(uint256(20762622233247511923695936235097668624236267066286198324889650888129013889247), uint256(18808079956460127806449929826355374365201492306347097052012324812670410791938));
        vk.IC[9] = Pairing.G1Point(uint256(6076683886643845371094500326016184106500086888084108657525314933663507672309), uint256(6752616616170354357064571790863753737747382057410087755033556515433242724330));
        vk.IC[10] = Pairing.G1Point(uint256(9032662365021851977462887613989195468122326720464514116812417560381385624210), uint256(16232611910528943000119678040135575572131902668301172239232125212158355014651));
        vk.IC[11] = Pairing.G1Point(uint256(18068229708999959426710558289916249304460200610443231963830617361283253436734), uint256(9067387427579569310615300681137878866376956153770242076971439003207939563883));
        vk.IC[12] = Pairing.G1Point(uint256(14134267451967483563327412728182246766086937141699262838161313807164220661151), uint256(18685441237563498472729990368213511084727533846916701322375499917172962985087));

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

