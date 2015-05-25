import unittest, rbtree, sequtils

proc `==`[T]( actual: RedBlackTree[T], expected: string ): bool =
    $actual == expected

suite "A Red/Black Tree should":

    test "Instantiate as an empty tree":
        let tree = newRBTree[int]()
        require( tree == "RedBlackTree()" )

    test "Insert Case 1":
        var tree = newRBTree[int]()
        tree.insert(1)
        require( tree == "RedBlackTree(B 1)" )

    test "Insert Case 2":
        var tree = newRBTree[int]()
        tree.insert(2, 1, 3)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

