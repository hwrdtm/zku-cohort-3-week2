//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        // A 3-level Merkle tree will have 8+4+2+1=15 hashes.
        // Alternatively, just declare hashes as a fixed-size array of 15
        // elements.

        // Calculate number of nodes in tree.
        uint256 numLevels = 3;
        uint256 numNodes = 0;
        for (uint256 l = 0; l <= numLevels; l++) {
            numNodes += 2**l;
        }

        // Initialize array element for each node in hashes array.
        for (uint8 i = 0; i < numNodes; i++) {
            hashes.push(0);
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree

        // Set leaf.
        hashes[index] = hashedLeaf;

        // Update hashes along path to root, including root itself.
        // Example:
        // - index=3, hash(2_,3), hash(8_,9), hash(12,13_)
        // - index=6, hash(6,7_), hash(10_,11), hash(12_,13)
        uint256 idxAtLevel = index;
        for (uint256 level = 3; level > 0; level--) {
            // Find out which index this level starts at.
            // Level 3 is the bottom-level.
            uint256 startingIdxOfLevel = getStartingIdxOfLevel(level);

            // Get actual index in hashes array.
            uint256 hashesIdx = startingIdxOfLevel + idxAtLevel;

            // Get index of parent hash to set.
            uint256 parentHashesIdx = getStartingIdxOfLevel(level - 1) +
                (idxAtLevel / 2);

            // Find out if idxAtLevel is even / odd to determine
            // if left / right sibling.
            bool isIdxAtLeftSibling = idxAtLevel % 2 == 0;

            // Calculate parent hash.
            uint256 parentHash = getParentHash(isIdxAtLeftSibling, hashesIdx);

            // Set parent's new hash.
            hashes[parentHashesIdx] = parentHash;

            // Update idxAtLevel
            idxAtLevel = idxAtLevel / 2;
        }

        // Finally, update index pointer.
        index++;

        // Set new merkle root.
        root = hashes[hashes.length - 1];

        // Return new merkle root.
        return root;
    }

    function getParentHash(bool isIdxAtLeftSibling, uint256 hashesIdx)
        private
        view
        returns (uint256)
    {
        if (isIdxAtLeftSibling) {
            // Hash with right sibling to get parent's new hash.
            return
                PoseidonT3.poseidon([hashes[hashesIdx], hashes[hashesIdx + 1]]);
        }

        // Hash with left sibling to get parent's new hash.
        return PoseidonT3.poseidon([hashes[hashesIdx - 1], hashes[hashesIdx]]);
    }

    // Example:
    // - level=3, return 0
    // - level=2, return 8
    // - level=1, return 12
    // - level=0, return 14
    function getStartingIdxOfLevel(uint256 level)
        private
        pure
        returns (uint256)
    {
        uint256 idx = 0;
        for (uint256 l = 3; l > level; l--) {
            idx += 2**l;
        }
        return idx;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root

        // input variable from calldata is also the calculated root
        // from the MerkleTreeInclusionProof - verify it against storage root.
        return verifyProof(a, b, c, input) && input[0] == root;
    }
}
