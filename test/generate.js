/**
 * Uses a javascript based red/black implementation to generate a set of
 * operations and the expected structure of the tree. Obviously, the weakness
 * here is that it depends on the correctness of the JS implementation.
 */
var tree = require('redblack').tree();

// The values that are currently in the tree
var values = []

/** Dumps the content of the tree */
function dump() {

    function toStr( node ) {
        if ( node === null ) {
            return "()";
        }
        else {
            return "(" +
                (node.color === 'red' ? "R" : "B") + " " +
                node.value +
                ( node.left === null && node.right === null ? "" :
                    " " + toStr(node.left) + " " + toStr(node.right) ) +
                ")";
        }
    }

    console.log("CMP " + toStr(tree.root))
}

/** Adds a random value to the tree */
function insert() {
    var value = Math.floor(Math.random() * Math.pow(2, 31));
    console.log("INS " + value);
    values.push(value);
    tree.insert(value, value);
}

/** Removes a random value from the tree */
function remove() {
    var index = Math.floor(Math.random() * values.length);
    console.log("DEL " + values[index]);
    tree.delete(values[index]);
    values.splice(index, 1);
}

// Start by validating the structure of an empty tree
dump();

// Every iteration represents an operation against the tree
for ( var i = 0; i < 50; i++ ) {
    if ( values.length === 0 ) {
        insert();
    }
    else if ( values.length < 50 ) {
        // Chance to do an insert for small trees
        Math.random() <= .9 ? insert() : remove();
    }
    else if ( values.length > 500 ) {
        // Chance to do a removal for large trees
        Math.random() <= .1 ? insert() : remove();
    }
    else {
        // Split chance to add/remove
        Math.random() <= .5 ? insert() : remove();
    }

    dump();
}

