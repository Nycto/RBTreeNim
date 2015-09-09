RBTreeNim [![Build Status](https://travis-ci.org/Nycto/RBTreeNim.svg?branch=master)](https://travis-ci.org/Nycto/RBTreeNim)
=========

A Red/Black Tree implementation in Nim

Red/Black trees are self balancing binary search trees that maintain structure
by tracking an extra bit of state about each node. This is then used to examine
relationships between parents and children, allowing appropriate rotations to
be performed. See
[Wikipedia](http://en.wikipedia.org/wiki/Red%E2%80%93black_tree) for more info.

API Docs
--------

http://nycto.github.io/RBTreeNim/rbtree.html

A Quick Tour
------------

```nimrod
import rbtree

# Create a new tree
var tree = newRBTree[int, int]()

# Insert 4 values into the tree. Insert accepts 1 or more arguments to insert
tree.insert(2, 3, 1, 0)

# Remove one of those values
tree.delete(1)

# Check whether a value exists in the tree
if tree.contains(3):
    echo "Tree contains '3'"

# Iterate over every value in the tree
for i in tree:
    echo i

# Or iterate in reverse
for i in reversed(tree):
    echo i
```

Custom Keys
-----------

A Red/Black tree has a concept of a 'key' and a 'comparator'. When you call
`fetch`, the key is what you pass in. Sometimes this is the object itself, but
other times it's a derived value. When that is the case, you can define an
`extract` function that returns the key.

For example, if you are indexing X/Y coordinates by just the `x` value:

```nimrod
import rbtree

proc extract( point: tuple[x, y: int] ): int = point.x

var tree = newRBTree[tuple[x, y: int], int]()

tree.insert( (x: 234, y: 789) )
tree.insert( (x: 890, y: 123) )

echo tree.contains(234)
echo tree
```

Custom Comparators
------------------

Values are inserted into a Red/Black Tree in sorted order. The definition of
"sorted order", howerver, can be customized by defining a `cmp` function.
It should take two values, `(a, b)`, and returns `< 0` if `a < b`, `> 0` if
`a > b`, and `0` if `x == y`.

For example, if you wanted to sort a tree of coordinates by their `y` values:

```nimrod
import rbtree

type MyPoint = object
    x, y: int

proc cmp*( a, b: MyPoint ): int = cmp(a.y, b.y)

var tree = newRBTree[MyPoint, MyPoint]()

tree.insert( MyPoint(x: 234, y: 789) )
tree.insert( MyPoint(x: 890, y: 123) )

echo tree
```

Multiple Indexes
----------------

Sometimes you will want to index the same object in different ways. However,
this library uses compile time references to hook in the `extract` and `cmp`
methods. To get around this, you can define a custom `distinct` type that
will allow you to dispatch to different `extract` and `cmp` implementations.

```nimrod
import rbtree

# Define new types with custom extractors and comparators
defineIndex(XIndex, tuple[x, y: int], it.x, cmp(a, b))
defineIndex(YIndex, tuple[x, y: int], it.y, cmp(a, b))

var xIndex = newRBTree[XIndex, int]()
var yIndex = newRBTree[YIndex, int]()

let point1 = (x: 234, y: 789)
let point2 = (x: 890, y: 123)

xIndex.insert(point1, point2)
yIndex.insert(point1, point2)

echo xIndex
echo yIndex
```

License
-------

This library is released under the MIT License, which is pretty spiffy. You
should have received a copy of the MIT License along with this program. If
not, see http://www.opensource.org/licenses/mit-license.php

