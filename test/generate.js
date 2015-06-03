/**
 * Uses a javascript based red/black implementation to generate a set of
 * operations and the expected structure of the tree. Obviously, the weakness
 * here is that it depends on the correctness of the JS implementation.
 */

// npm install bintrees
var RBTree = require('bintrees').RBTree;

var tree = new RBTree(function(a, b) { return a - b; });

// The values that are currently in the tree
var values = []

// Whether to dump comparison data
var noDump = process.argv.indexOf("--dump") === -1;

// The number of iterations
var iterations = parseInt(
    process.argv[process.argv.indexOf("--iter") + 1] || "1000", 10);

/** Dumps the content of the tree */
function dump() {
    if ( noDump ) {
        return;
    }

    function toStr( node ) {
        if ( node === null ) {
            return "()";
        }
        else {
            return "(" +
                (node.red ? "R" : "B") + " " +
                node.data +
                ( node.left === null && node.right === null ? "" :
                    " " + toStr(node.left) + " " + toStr(node.right) ) +
                ")";
        }
    }

    console.log("CMP " + toStr(tree._root))
}

/** Adds a random value to the tree */
function insert() {
    var value = Math.floor(Math.random() * 9999);
    console.log("INS " + value);
    values.push(value);
    tree.insert(value);
}

/** Removes a random value from the tree */
function remove() {
    var index = Math.floor(Math.random() * values.length);
    console.log("DEL " + values[index]);
    tree.remove(values[index]);
    values.splice(index, 1);
}

// Start by validating the structure of an empty tree
dump();

// Every iteration represents an operation against the tree
for ( var i = 0; i < iterations; i++ ) {
    if ( values.length === 0 ) {
        insert();
    }
    else if ( values.length < 50 ) {
        // Chance to do an insert for small trees
        Math.random() <= .8 ? insert() : remove();
    }
    else if ( values.length > 500 ) {
        // Chance to do a removal for large trees
        Math.random() <= .2 ? insert() : remove();
    }
    else {
        // Split chance to add/remove
        Math.random() <= .5 ? insert() : remove();
    }

    dump();
}

