import unittest, rbtree, sequtils

abortOnError = true

proc `==`[T, K]( actual: RedBlackTree[T, K], expected: string ): bool =
    ## Compares a tree to an expected serialized version
    let actualStr = $actual
    checkpoint("Expecting: " & expected)
    checkpoint("Tree is:   " & actualStr)
    validate(actual)
    actualStr == expected


# Define a custom object with the 'defineIndex' module
defineIndex(ModuloInt, int, it, (a mod 5) - (b mod 5))


# Test object with a compare, but no extract
type MyObj = object
    idx: int

proc cmp( a, b: MyObj ): int =
    cmp(a.idx, b.idx)


suite "A Red/Black Tree with a custom index":

    test "Custom index via defineIndex":
        var tree = newRBTree[ModuloInt, ModuloInt]()
        tree.insert(4, 10, 7, 16, 13, 8)
        let asSeq: seq[int] = toSeq(items(tree)).mapIt(int, int(it))
        require(asSeq == @[ 10, 16, 7, 13, 8, 4 ])

    test "Allow a `compare` without an extract":
        var tree = newRBTree[MyObj, MyObj]()
        tree.insert( MyObj(idx: 50), MyObj(idx: 30), MyObj(idx: 40) )
        let asSeq: seq[int] = toSeq(items(tree)).mapIt(int, it.idx)
        require(asSeq == @[ 30, 40, 50 ])

