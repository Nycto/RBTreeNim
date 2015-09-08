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

Multiple Indexes
----------------

Sometimes you will want to index the same object in different ways. However,
this library uses compile time references to hook in the `extract` and `cmp`
methods. To get around this, you can define a custom `distinct` type that
will allow you to dispatch to different `extract` and `cmp` implementations.

```nimrod
import rbtree

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

