pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n]; // already hashed leaves.
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    // Calculate total number of hashes needed to compute merkle root.
    // Note that this is ALWAYS odd.
    var numHashes = calculateNumberOfHashes(n);

    // Examples:
    // - n=1, leaves=2, hashes=2+1, poseidon=1
    // - n=2, leaves=4, hashes=4+3, poseidon=3
    // - n=3, leaves=8, hashes=8+7, poseidon=7

    // Init the array of hashes, prepended with hashed leaves.
    component hashes[2**n + numHashes];
    for (var i = 0; i < 2**n; i++) {
        hashes[i] = leaves[i];
    }

    // Init the Poseidon(2) components.
    component poseidon[numHashes];

    // Keep index reference for outputing hash computations.
    // This is initialized to be the next index after all the 
    // leaf hashes.
    // Example:
    // - n=1, leaves=2, hashes=2+1, poseidon=1, hashOutputIdx=2
    // - n=2, leaves=4, hashes=4+3, poseidon=3, hashOutputIdx=4
    // - n=3, leaves=8, hashes=8+7, poseidon=7, hashOutputIdx=8
    var hashOutputIdx = 2**n;

    // Calculate merkle root using populated hashes array.
    for (var i = 0; i < numHashes; i++) {
        // Create the Poseidon(2) component.
        poseidon[i] = Poseidon(2);

        // Calculate pairwise hashes.
        poseidon[i].inputs[0] <== hashes[i*2];
        poseidon[i].inputs[1] <== hashes[i*2+1];

        // Store hash result.
        hashes[hashOutputIdx] <== poseidon[i].out;

        // Increment variables.
        hashOutputIdx++;
    }

    // Last element of hashes array is the root.
    root <== hashes[2**n + numHashes - 1];
}

// Examples:
// - levels = 2, hashes = 3.
// - levels = 3, hashes = 7.
function calculateNumberOfHashes(levels) {
    var hashes;
    for (var i = levels-1; i > -1; i--) {
        hashes += 2**i;
    }
    return hashes;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    // Init mutable runningHash variable to track hash outputs.
    var runningHash = leaf;

    // Init the Poseidon(2) components.
    component poseidon[n];

    // Create intermediate signals for calculating Poseidon hashes.
    signal inter0[n];
    signal inter1[n];

    for (var i = 0; i < n; i++) {
        // Create Poseidon(2) component.
        poseidon[i] = Poseidon(2);

        // Compute next hash.
        // Instead of using if-else condition here on unknown
        // parameters in path_elements, convert into quadratic
        // expression.
        inter0[i] <== (1-path_index[i])*runningHash;
        poseidon[i].inputs[0] <== inter0[i] + path_index[i]*path_elements[i];

        inter1[i] <== (1-path_index[i])*path_elements[i];
        poseidon[i].inputs[1] <== inter1[i] + path_index[i]*runningHash;

        runningHash = poseidon[i].out;
    }

    root <== runningHash;
}

