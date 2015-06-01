import unittest, rbtree, sequtils, optional_t

proc `==`[T]( actual: RedBlackTree[T], expected: string ): bool =
    checkpoint("Tree is:   " & $actual)
    checkpoint("Expecting: " & expected)
    validate(actual)
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

    test "Reverse Iteration":
        var tree = newRBTree[int]()
        tree.insert(16,19,11,7,5,4,2,15,20,3,6,8,13,14,1,12,18,17,10,9)
        let asSeq = toSeq(reversed(tree))
        require(asSeq == @[20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1])

    test "Custom sorting":
        var tree = newRBTree[int]() do (a, b: int) -> int:
            return (a mod 5) - (b mod 5)
        tree.insert(4,10,7,16,13)
        let asSeq = toSeq(items(tree))
        require(asSeq == @[ 10, 16, 7, 13, 4 ])

    test "Return whether an item is included":
        var tree = newRBTree[int]()
        require( not tree.contains(4) )
        tree.insert(4,10,10,7,16,13)
        require( tree.contains(4) )
        require( tree.contains(10) )
        require( tree.contains(16) )
        require( not tree.contains(20) )

    test "Return the minimum value in a true":
        var tree = newRBTree[int]()
        require( tree.min.isNone )
        tree.insert(10,4,7,16,13)
        require( tree.min.get == 4 )

    test "Return the maximum value in a true":
        var tree = newRBTree[int]()
        require( tree.max.isNone )
        tree.insert(10,4,7,16,13)
        require( tree.max.get == 16 )

    test "Deleting a value that doesn't exist is a noop":
        var tree = newRBTree[int]()
        tree.delete(15)
        require( tree == "RedBlackTree()" )
        tree.insert(10,4,7)
        tree.delete(15)
        require( tree == "RedBlackTree(B 7 (R 4) (R 10))" )

    test "Deleting the only node from a tree":
        var tree = newRBTree[int]()
        tree.insert(10)
        tree.delete(10)
        require( tree == "RedBlackTree()" )

    test "Deleting the only node from a tree":
        var tree = newRBTree[int]()
        tree.insert(10)
        tree.delete(10)
        require( tree == "RedBlackTree()" )

    test "Deleting a red leaf from a tree":
        var tree = newRBTree[int]()
        tree.insert(1, 2, 3)
        tree.delete(3)
        require( tree == "RedBlackTree(B 2 (R 1) ())" )
        tree.delete(1)
        require( tree == "RedBlackTree(B 2)" )

    test "Delete case 1":
        var tree = newRBTree[int]()
        tree.insert(1, 2, 3)
        tree.delete(2)
        require( tree == "RedBlackTree(B 1 () (R 3))" )

    test "Delete case 2 (rotate left) and case 4":
        var tree = newRBTree[int]()
        tree.insert(5, 2, 7, 6, 8, 9)
        tree.delete(2)
        require( tree == "RedBlackTree(B 7 (B 5 () (R 6)) (B 8 () (R 9)))" )

    test "Delete case 2 (rotate right) and case 4":
        var tree = newRBTree[int]()
        tree.insert(5, 6, 3, 2, 4, 1)
        tree.delete(6)
        require( tree == "RedBlackTree(B 3 (B 2 (R 1) ()) (B 5 (R 4) ()))" )

    test "Delete case 3":
        var tree = newRBTree[int]()
        tree.insert(1, 2, 3, 4)
        tree.delete(4)
        tree.delete(1)
        require( tree == "RedBlackTree(B 2 () (R 3))" )

    test "Delete case 5 (rotate left)":
        var tree = newRBTree[int]()
        tree.insert(1, 2, 5, 6, 3, 4)
        tree.delete(6)
        require( tree == "RedBlackTree(B 2 (B 1) (R 4 (B 3) (B 5)))" )

    test "Delete case 5 (rotate right)":
        var tree = newRBTree[int]()
        tree.insert(5, 2, 6, 1, 4, 3)
        tree.delete(1)
        require( tree == "RedBlackTree(B 5 (R 3 (B 2) (B 4)) (B 6))" )

    test "Delete case 6 (rotate left)":
        var tree = newRBTree[int]()
        tree.insert(50, 75, 25, 70, 80)
        tree.delete(25)
        require( tree == "RedBlackTree(B 75 (B 50 () (R 70)) (B 80))" )

    test "Delete case 6 (rotate right)":
        var tree = newRBTree[int]()
        tree.insert(5, 2, 6, 1, 3)
        tree.delete(6)
        require( tree == "RedBlackTree(B 2 (B 1) (B 5 (R 3) ()))" )

