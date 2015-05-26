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

    test "Insert Case 3":
        var tree = newRBTree[int]()
        tree.insert(2, 3, 1, 0)
        require( tree == "RedBlackTree(B 2 (B 1 (R 0) ()) (B 3))" )

    test "Insert Case 4 (rotate left)":
        var tree = newRBTree[int]()
        tree.insert(3, 1, 2)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (rotate right)":
        var tree = newRBTree[int]()
        tree.insert(1, 3, 2)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (no rotation), case 5 (rotate left)":
        var tree = newRBTree[int]()
        tree.insert(1, 2, 3)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (no rotate), case 5 (rotate right)":
        var tree = newRBTree[int]()
        tree.insert(3, 2, 1)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert 10 nodes":
        var tree = newRBTree[int]()
        tree.insert(8,1,2,5,3,10,6,4,7,9)
        require( tree == "RedBlackTree" &
            "(B 5 " &
                "(R 2 (B 1) (B 3 () (R 4))) " &
                "(R 8 (B 6 () (R 7)) (B 10 (R 9) ())))"
        )

    test "Iteration":
        var tree = newRBTree[int]()
        tree.insert(16,19,11,7,5,4,2,15,20,3,6,8,13,14,1,12,18,17,10,9)
        let asSeq = toSeq(items(tree))
        require(asSeq == @[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])


