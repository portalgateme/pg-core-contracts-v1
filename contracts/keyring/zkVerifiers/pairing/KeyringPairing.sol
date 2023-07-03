// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions 
// of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
// OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
// 2023 Keyring
//      removed commented code
//      add whitespace
//      remove redundant success checks
//      reorganize comments and pragma
//      remove unused p1() and p()
//      fix linter issues
//      remove unused pairing functions
//      ported to 0.8.14
//      add BASE_MODULUS and SCALAR_MODULUS
//      add InvalidProof()

library KeyringPairing {

    error InvalidProof();

	struct VerifyingKey {
		KeyringPairing.G1Point alfa1;
		KeyringPairing.G2Point beta2;
		KeyringPairing.G2Point gamma2;
		KeyringPairing.G2Point delta2;
		KeyringPairing.G1Point[] ic;
	}

	struct Proof {
		KeyringPairing.G1Point a;
		KeyringPairing.G2Point b;
		KeyringPairing.G1Point c;
	}

    // The prime q in the base field F_q for G1
    uint256 constant internal BASE_MODULUS = 
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // The prime moludus of the scalar field of G1.
    uint256 constant internal SCALAR_MODULUS = 
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint x;
        uint y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] x;
        uint[2] y;
    }

    /// @return r The negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        if (p.x == 0 && p.y == 0) return G1Point(0, 0);
        // Validate input or revert
        if (p.x >= BASE_MODULUS || p.y >= BASE_MODULUS) revert InvalidProof();
        // We know p.Y > 0 and p.Y < BASE_MODULUS.
        return G1Point(p.x, BASE_MODULUS - p.y);
    }

    /// @return r The sum of two points of G1
    function addition(G1Point memory p1_, G1Point memory p2_) internal view returns (G1Point memory r) {
        // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
        // on the curve.
        uint[4] memory input;
        input[0] = p1_.x;
        input[1] = p1_.y;
        input[2] = p2_.x;
        input[3] = p2_.y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        }
        if(!success) revert InvalidProof();
    }

    /// @return r The product of a point on G1 and a scalar, i.e.
    /// @dev p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalarMul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
        // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
        if (s >= SCALAR_MODULUS) revert InvalidProof();        
        uint[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        }
        if (!success) revert InvalidProof();
    }

    /// @notice Pairing check.
    /// @dev e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// @return isValid True if the proof passes the pairing check. 
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool isValid) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].x;
            input[i * 6 + 1] = p1[i].y;
            input[i * 6 + 2] = p2[i].x[0];
            input[i * 6 + 3] = p2[i].x[1];
            input[i * 6 + 4] = p2[i].y[0];
            input[i * 6 + 5] = p2[i].y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        isValid = success && out[0] == 1;
    }

}
