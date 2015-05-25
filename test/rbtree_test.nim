import unittest, rbtree

suite "A Red/Black Tree should":

    test "Instantiate as an empty tree":
        let tree = newRBTree[int]()
        require( $tree == "RedBlackTree()" )

