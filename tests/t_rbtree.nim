import unittest, rbtree, sequtils, strutils, options

abortOnError = true

proc `==`[T, K]( actual: RedBlackTree[T, K], expected: string ): bool =
    ## Compares a tree to an expected serialized version
    let actualStr = $actual
    checkpoint("Expecting: " & expected)
    checkpoint("Tree is:   " & actualStr)
    validate(actual)
    actualStr == expected

proc extract( value: tuple[i: int] ): int = value.i
    ## Simple tuple extractor

proc extract( value: tuple[x, y: int] ): int = value.x
    ## Index a point by the x value

proc compareTails( expect: string, drop: int, versus: string ): bool =
    ## Returns whether two strings end with the same value
    for i in countup(drop, expect.len - 1):
        if expect[i] != versus[i + versus.len - expect.len]:
            return false
    return true

proc runGauntlet( file: string ) =
    ## Pulls commands from a file and executes them against a tree
    var tree = newRBTree[int, int]()

    var lineNumber = 0
    for line in lines(file):
        lineNumber = lineNumber + 1

        let command = line[0..2]
        proc content: string = line[4..<line.len]

        try:
            case command
            of "CMP":
                validate(tree)
                let valid = compareTails(line, 4, $tree)
                if not valid:
                    checkpoint("Expected: RedBlackTree" & content())
                    checkpoint("Tree is:  " & $tree)
                    assert(false)
            of "INS":
                tree.insert( parseInt(content()) )
                validate(tree)
            of "DEL":
                tree.delete( parseInt(content()) )
                validate(tree)
            else:
                raise newException(AssertionError,
                    "Unknown test command: " & command)
        except:
            checkpoint("Script line #" & $lineNumber)
            raise

suite "A Red/Black Tree should":

    test "Instantiate as an empty tree":
        let tree = newRBTree[int, int]()
        require( tree == "RedBlackTree()" )

    test "Insert Case 1":
        var tree = newRBTree[int, int]()
        tree.insert(1)
        require( tree == "RedBlackTree(B 1)" )

    test "Insert Case 2":
        var tree = newRBTree[int, int]()
        tree.insert(2, 1, 3)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 3":
        var tree = newRBTree[int, int]()
        tree.insert(2, 3, 1, 0)
        require( tree == "RedBlackTree(B 2 (B 1 (R 0) ()) (B 3))" )

    test "Insert Case 4 (rotate left)":
        var tree = newRBTree[int, int]()
        tree.insert(3, 1, 2)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (rotate right)":
        var tree = newRBTree[int, int]()
        tree.insert(1, 3, 2)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (no rotation), case 5 (rotate left)":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert Case 4 (no rotate), case 5 (rotate right)":
        var tree = newRBTree[int, int]()
        tree.insert(3, 2, 1)
        require( tree == "RedBlackTree(B 2 (R 1) (R 3))" )

    test "Insert 10 nodes":
        var tree = newRBTree[int, int]()
        tree.insert(8,1,2,5,3,10,6,4,7,9)
        require( tree == "RedBlackTree" &
            "(B 5 " &
                "(R 2 (B 1) (B 3 () (R 4))) " &
                "(R 8 (B 6 () (R 7)) (B 10 (R 9) ())))"
        )

    test "Inserting the same value should add them to the right":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3)
        tree.insert(3)
        require(tree == "RedBlackTree(B 2 (B 1) (B 3 () (R 3)))")
        tree.insert(3)
        require(tree == "RedBlackTree(B 2 (B 1) (B 3 (R 3) (R 3)))")
        tree.insert(1)
        require(tree == "RedBlackTree(B 2 " &
            "(B 1 () (R 1)) " &
            "(B 3 (R 3) (R 3)))")
        tree.insert(1)
        require(tree == "RedBlackTree(B 2 " &
            "(B 1 (R 1) (R 1)) " &
            "(B 3 (R 3) (R 3)))")

    test "Iteration":
        var tree = newRBTree[int, int]()
        tree.insert(16,19,11,7,5,4,2,15,20,3,6,8,13,14,1,12,18,17,10,9)
        let asSeq = toSeq(items(tree))
        require(asSeq == @[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])

    test "Reverse Iteration":
        var tree = newRBTree[int, int]()
        tree.insert(16,19,11,7,5,4,2,15,20,3,6,8,13,14,1,12,18,17,10,9)
        let asSeq = toSeq(reversed(tree))
        require(asSeq == @[20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1])

    test "Return whether an item is included":
        var tree = newRBTree[int, int]()
        require( not tree.contains(4) )
        tree.insert(4,10,10,7,16,13)
        require( tree.contains(4) )
        require( tree.contains(10) )
        require( tree.contains(16) )
        require( not tree.contains(20) )

    test "Return whether an item is included based on the key or value":
        var tree = newRBTree[tuple[x, y: int], int]()
        require( not tree.contains(50) )
        tree.insert( (x: 50, y: 4), (x: 30, y: 5), (x: 40, y: 90) )

        require( tree.contains(50) )
        require( tree.contains((x: 50, y: 4)) )
        require( tree.contains(30) )
        require( tree.contains((x: 30, y: 5)) )
        require( tree.contains(40) )
        require( tree.contains((x: 40, y: 90)) )

        require( not tree.contains((x: 40, y: 30)) )
        require( not tree.contains(20) )

        tree.delete((x: 50, y: 4))
        require( not tree.contains(50) )

    test "Return the minimum value in a true":
        var tree = newRBTree[int, int]()
        require( tree.min.isNone )
        tree.insert(10,4,7,16,13)
        require( tree.min.get == 4 )

    test "Return the maximum value in a true":
        var tree = newRBTree[int, int]()
        require( tree.max.isNone )
        tree.insert(10,4,7,16,13)
        require( tree.max.get == 16 )

    test "Deleting a value that doesn't exist is a noop":
        var tree = newRBTree[int, int]()
        tree.delete(15)
        require( tree == "RedBlackTree()" )
        tree.insert(10,4,7)
        tree.delete(15)
        require( tree == "RedBlackTree(B 7 (R 4) (R 10))" )

    test "Deleting the only node from a tree":
        var tree = newRBTree[int, int]()
        tree.insert(10)
        tree.delete(10)
        require( tree == "RedBlackTree()" )

    test "Deleting the only node from a tree":
        var tree = newRBTree[int, int]()
        tree.insert(10)
        tree.delete(10)
        require( tree == "RedBlackTree()" )

    test "Deleting a red leaf from a tree":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3)
        tree.delete(3)
        require( tree == "RedBlackTree(B 2 (R 1) ())" )
        tree.delete(1)
        require( tree == "RedBlackTree(B 2)" )

    test "Delete case 1":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3)
        tree.delete(2)
        require( tree == "RedBlackTree(B 1 () (R 3))" )

    test "Delete case 2 (rotate left) and case 4":
        var tree = newRBTree[int, int]()
        tree.insert(5, 2, 7, 6, 8, 9)
        tree.delete(2)
        require( tree == "RedBlackTree(B 7 (B 5 () (R 6)) (B 8 () (R 9)))" )

    test "Delete case 2 (rotate right) and case 4":
        var tree = newRBTree[int, int]()
        tree.insert(5, 6, 3, 2, 4, 1)
        tree.delete(6)
        require( tree == "RedBlackTree(B 3 (B 2 (R 1) ()) (B 5 (R 4) ()))" )

    test "Delete case 3":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3, 4)
        tree.delete(4)
        tree.delete(1)
        require( tree == "RedBlackTree(B 2 () (R 3))" )

    test "Delete case 5 (rotate left)":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 5, 6, 3, 4)
        tree.delete(6)
        require( tree == "RedBlackTree(B 2 (B 1) (R 4 (B 3) (B 5)))" )

    test "Delete case 5 (rotate right)":
        var tree = newRBTree[int, int]()
        tree.insert(5, 2, 6, 1, 4, 3)
        tree.delete(1)
        require( tree == "RedBlackTree(B 5 (R 3 (B 2) (B 4)) (B 6))" )

    test "Delete case 6 (rotate left)":
        var tree = newRBTree[int, int]()
        tree.insert(50, 75, 25, 70, 80)
        tree.delete(25)
        require( tree == "RedBlackTree(B 75 (B 50 () (R 70)) (B 80))" )

    test "Delete case 6 (rotate right)":
        var tree = newRBTree[int, int]()
        tree.insert(5, 2, 6, 1, 3)
        tree.delete(6)
        require( tree == "RedBlackTree(B 2 (B 1) (B 5 (R 3) ()))" )

    test "Delete predecessor is a right branch":
        var tree = newRBTree[int, int]()
        tree.insert(5, 3, 6, 4)
        tree.delete(5)
        require( tree == "RedBlackTree(B 4 (B 3) (B 6))" )

    test "Deleting a node with a left child but no right":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 4, 3)
        tree.delete(4)
        require( tree == "RedBlackTree(B 2 (B 1) (B 3))" )

    test "Deleting a node with a right child but no left":
        var tree = newRBTree[int, int]()
        tree.insert(1, 2, 3, 4)
        tree.delete(3)
        require( tree == "RedBlackTree(B 2 (B 1) (B 4))" )

    test "Calculate the ceil within a tree":
        var tree = newRBTree[tuple[i: int], int]()

        require( ceil(tree, 25) == none(tuple[i: int]) )

        tree.insert(
            (i: 10), (i: 20), (i: 30), (i: 40), (i: 50),
            (i: 60), (i: 70), (i: 80), (i: 55), (i: 57))

        require( ceil(tree, 40) == some[tuple[i: int]]((i: 40)) )
        require( ceil(tree, 50) == some[tuple[i: int]]((i: 50)) )
        require( ceil(tree, 65) == some[tuple[i: int]]((i: 70)) )
        require( ceil(tree, 0) == some[tuple[i: int]]((i: 10)) )
        require( ceil(tree, 54) == some[tuple[i: int]]((i: 55)) )
        require( ceil(tree, 56) == some[tuple[i: int]]((i: 57)) )
        require( ceil(tree, 59) == some[tuple[i: int]]((i: 60)) )
        require( ceil(tree, 90) == none(tuple[i: int]) )

    test "Calculate the floor within a tree":
        var tree = newRBTree[tuple[i: int], int]()

        require( floor(tree, 25) == none(tuple[i: int]) )

        tree.insert(
            (i: 10), (i: 20), (i: 30), (i: 40), (i: 50),
            (i: 60), (i: 70), (i: 80), (i: 55), (i: 57))

        require( floor(tree, 40) == some[tuple[i: int]]((i: 40)) )
        require( floor(tree, 50) == some[tuple[i: int]]((i: 50)) )
        require( floor(tree, 75) == some[tuple[i: int]]((i: 70)) )
        require( floor(tree, 90) == some[tuple[i: int]]((i: 80)) )
        require( floor(tree, 56) == some[tuple[i: int]]((i: 55)) )
        require( floor(tree, 58) == some[tuple[i: int]]((i: 57)) )
        require( floor(tree, 61) == some[tuple[i: int]]((i: 60)) )
        require( floor(tree, 5) == none(tuple[i: int]) )

    test "Return whether a tree is empty":
        var tree = newRBTree[int, int]()
        require( tree.isEmpty )

        tree.insert(1)
        require( not tree.isEmpty )

        tree.insert(2)
        require( not tree.isEmpty )

        tree.delete(1)
        tree.delete(2)
        require( tree.isEmpty )

    test "Find should return a value from a key":
        var tree = newRBTree[tuple[x, y: int], int]()

        tree.insert( (x: 50, y: 4), (x: 30, y: 5), (x: 40, y: 90) )

        require( tree.find(50) == some((x: 50, y: 4)) )
        require( tree.find(30) == some((x: 30, y: 5)) )
        require( tree.find(40) == some((x: 40, y: 90)) )
        require( tree.find(0) == none(tuple[x, y: int]) )
        require( tree.find(90) == none(tuple[x, y: int]) )

    test "Maintain red/black rules through a large number of ops":
        runGauntlet("./tests/10000_operations.txt")

