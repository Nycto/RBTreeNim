import unittest, rbtree, sequtils

proc `==`[T]( actual: RedBlackTree[T], expected: string ): bool =
    $actual == expected

suite "A Red/Black Tree should":

    test "Instantiate as an empty tree":
        let tree = newRBTree[int]()
        require( tree == "RedBlackTree()" )

    test "Insert nodes":
        var tree = newRBTree[int]()

        tree.insert(1)
        require( tree == "RedBlackTree(B 1)" )

