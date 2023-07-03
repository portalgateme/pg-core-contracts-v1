# ZK Verifiers

Pairing lib and zero-knowledge verifier contracts. 

## Deployment ceremony

Zero-knowledge Proofs require the input of certain constants that should be generated in a demonstrably open and tamper-resistent fashion. These "ceremonies" generally involve assembling a group of participants with the mathematical guarantee that the system is resistent to cryptographic attack (in this context, an adversary acquiring the ability to reveal a secret that is meant to be confidential) provided that at least one ceremony participant is honest. 

As such, Keyring will organize and execute such a ceremory prior to deploying Keying Network in a production setting. 

The `zkVerifiers` are representative of the final code and are suitable for testing. The final, production versions of the `zkVerifiers` will be substantially the same but will differ in that certain hard-coded parameters will change following a formal launch ceremony. 
