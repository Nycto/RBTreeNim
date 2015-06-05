RBTreeNim [![Build Status](https://travis-ci.org/Nycto/RBTreeNim.svg?branch=master)](https://travis-ci.org/Nycto/RBTreeNim)
=========

A Red/Black Tree implementation in Nim

API Docs
--------

http://nycto.github.io/RBTreeNim/rbtree.html

A Quick Tour
------------

```nimrod
import rbtree

# Create a new tree
var tree = newRBTree[int]()

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

Custom Comparators
------------------

When instantiating a tree, you can define a custom compare proc. This allows
you to store arbitrary structures in the tree.

```nimrod
import rbtree

# Store points in a tree, but index them only by the `x` value
var tree = newRBTree[tuple[x, y: int]]() do (a, b: tuple[x, y: int]) -> int:
    return a.x - b.x

tree.insert( (x: 5, y: 2), (x: 3, y: 8), (x: 10, y: 0) )

echo tree
```

License
-------

This library is released under the MIT License, which is pretty spiffy. You
should have received a copy of the MIT License along with this program. If
not, see http://www.opensource.org/licenses/mit-license.php

