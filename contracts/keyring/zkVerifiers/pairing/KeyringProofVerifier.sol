// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./KeyringPairing.sol";
import "../../interfaces/IKeyringProofVerifier.sol";

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
//      added require error messages
//
// 2023 Keyring
//      removed commented code
//      add whitespace
//      external pairing library
//      remove redundant success checks
//      reorganize comments and pragma
//      remove unused p1() and p()
//      fix linter issues
//      remove unused pairing functions
//      ported to solisity 0.8.14
//      use dynamic input arrays
//      virtual verifyingKeys

abstract contract KeyringProofVerifier is IKeyringProofVerifier {

	using KeyringPairing for *;

    function verifyingKey() internal pure virtual returns (KeyringPairing.VerifyingKey memory vk);

	/// @dev Verifies a Semaphore proof.
	/// @return isValid True if the proof is valid.
    function verify(
        uint[] memory input, 
        KeyringPairing.Proof memory proof
    ) internal view returns (bool) {
        
        KeyringPairing.VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.ic.length,"verifier-bad-input");
        // Compute the linear combination vkX
        KeyringPairing.G1Point memory vkX = KeyringPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < KeyringPairing.SCALAR_MODULUS,"verifier-gte-snark-scalar-field");
            if (input[i] != 0) {
                vkX = KeyringPairing.addition(vkX, KeyringPairing.scalarMul(vk.ic[i + 1], input[i]));
            }
        }
        vkX = KeyringPairing.addition(vkX, vk.ic[0]);

        KeyringPairing.G1Point[] memory g1Points = new KeyringPairing.G1Point[](4);
        KeyringPairing.G2Point[] memory g2Points = new KeyringPairing.G2Point[](4);

        g1Points[0] = KeyringPairing.negate(proof.a);
        g2Points[0] = proof.b;

        g1Points[1] = vk.alfa1;
        g2Points[1] = vk.beta2;

        g1Points[2] = vkX;
        g2Points[2] = vk.gamma2;

        g1Points[3] = proof.c;
        g2Points[3] = vk.delta2;

        return KeyringPairing.pairing(
            g1Points,
            g2Points
        );
    }

    /// @return isValid True if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[] memory input
        ) public view returns (bool isValid) {
        KeyringPairing.Proof memory proof;
        proof.a = KeyringPairing.G1Point(a[0], a[1]);
        proof.b = KeyringPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = KeyringPairing.G1Point(c[0], c[1]);
        isValid = verify(input, proof);
    }
}
