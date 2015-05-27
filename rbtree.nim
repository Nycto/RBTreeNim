#
# A red/black binary search tree
#

import strutils, optional_t

type
    Color = enum ## The color of a node
        red, black

    Node[T] = ref object ## A node within a red/black tree

        # The (potential) connections in this node
        left, right, parent: Node[T]

        # The color of this node
        color: Color

        # The  value of this node
        value: T

    RedBlackTree*[T] = object ## A Red/Black tree

        compare: proc (a, b: T): int

        # The root of the tree
        root: Node[T]


proc newRBTree*[T]( compare: proc (a, b: T): int = cmp ): RedBlackTree[T] =
  # Creates a new Red/Black tree
  return RedBlackTree[T]( root: nil, compare: compare )

proc `$` [T]( self: Node[T] ): string =
    ## Converts a node to a string
    if self == nil:
        result = "()"
    else:
        result = "(" &
            (if self.color == red: "R" else: "B") & " " &
            $(self.value)
        if self.left != nil or self.right != nil:
            result.add(" " & $(self.left) & " " & $(self.right))
        result.add(")")

proc `$`* [T]( self: RedBlackTree[T] ): string =
    ## Returns a tree as a string
    return "RedBlackTree" & `$`[T](self.root)


proc newNode[T]( value: T, parent: Node[T] = nil ): Node[T] =
    return Node[T](
        left: nil, right: nil, parent: parent, color: red, value: value )

proc insert[T](
    self: var Node[T], compare: proc(a, b: T): int, value: T
): Node[T] =
    ## Does a basic binary search tree insert, returning the new node
    if compare(value, self.value) <= 0:
        if self.left == nil:
            result = newNode( value, self )
            self.left = result
        else:
            result = insert(self.left, compare, value)
    else:
        if self.right == nil:
            result = newNode( value, self )
            self.right = result
        else:
            result = insert(self.right, compare, value)

proc grandparent[T](node: var Node[T]): Node[T] {.inline.} =
    ## Returns the grandparent of a node; the parent of a parent
    if node != nil and node.parent != nil:
        return node.parent.parent
    else:
        return nil

proc uncle[T](node: var Node[T]): Node[T] {.inline.} =
    ## Returns the uncle (the parent's sibling) of a node
    let grandparent = grandparent(node)
    if grandparent == nil:
        return nil # No grandparent means no uncle
    elif node.parent == grandparent.left:
        return grandparent.right
    else:
        return grandparent.left

proc rotateLeft[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    var parent = node.parent
    if parent == nil:
        return

    var grandparent = parent.parent
    var child = node.left

    # Move the child over
    parent.right = child
    if child != nil:
        child.parent = parent

    # Move the parent around
    node.left = parent
    parent.parent = node

    # Move the node itself
    node.parent = grandparent

    # Update the grandparent, swapping the root of the tree if needed
    if grandparent == nil:
        tree.root = node
    elif grandparent.left == parent:
        grandparent.left = node
    else:
        grandparent.right = node

proc rotateRight[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    var parent = node.parent
    if parent == nil:
        return

    var grandparent = parent.parent
    var child = node.right

    # Move the child over
    parent.left = child
    if child != nil:
        child.parent = parent

    # Move the parent around
    node.right = parent
    parent.parent = node

    # Move the node itself
    node.parent = grandparent

    # Update the grandparent, swapping the root of the tree if needed
    if grandparent == nil:
        tree.root = node
    elif grandparent.left == parent:
        grandparent.left = node
    else:
        grandparent.right = node

proc isRightChild[T]( self: Node[T] ): bool =
    ## Whether this node is the right child of its parent
    self.parent != nil and self.parent.right == self

proc isLeftChild[T]( self: Node[T] ): bool =
    ## Whether this node is the left child of its parent
    self.parent != nil and self.parent.left == self

proc leftmost[T]( node: Node[T] ): Node[T] =
    ## Walks every left-ward child down to the bottom
    result = node
    while result != nil and result.left != nil:
        result = result.left

proc rightmost[T]( node: Node[T] ): Node[T] =
    ## Walks every rightward-ward child down to the bottom
    result = node
    while result != nil and result.right != nil:
        result = result.right


proc insertCase1[T]( tree: var RedBlackTree[T], node: var Node[T] )

proc insertCase5[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 5: The parent P is red but the uncle U is black, the current node N
    ## is the left child of P, and P is the left child of its parent G
    var grandparent = grandparent(node)
    node.parent.color = black
    grandparent.color = red
    if node == node.parent.left:
        rotateRight(tree, node.parent)
    else:
        rotateLeft(tree, node.parent)

proc insertCase4[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 4: The parent P is red but the uncle U is black; also, the current
    ## node N is the right child of P, and P in turn is the left child of its
    ## parent G
    let grandparent = grandparent(node)
    if node == node.parent.right and node.parent == grandparent.left:
        rotateLeft(tree, node)
        insertCase5(tree, node.left)
    elif node == node.parent.left and node.parent == grandparent.right:
        rotateRight(tree, node)
        insertCase5(tree, node.right)
    else:
        insertCase5(tree, node)

proc insertCase3[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 3: If both the parent P and the uncle U are red, then both of them
    ## can be repainted black and the grandparent G becomes red (to maintain
    ## that all paths from any given node to its leaf nodes contain the same
    ## number of black nodes)
    var uncle = uncle(node)
    if uncle != nil and uncle.color == red:
        node.parent.color = black
        uncle.color = black
        var grandparent = grandparent(node)
        grandparent.color = red
        insertCase1(tree, grandparent)
    else:
        insertCase4(tree, node)

proc insertCase2[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 2: The current node's parent P is black, so both children of every
    ## red node are black
    if node.parent.color == black:
        discard # Tree is still valid
    else:
        insertCase3(tree, node)

proc insertCase1[T]( tree: var RedBlackTree[T], node: var Node[T] ) =
    ## Case 1: The current node N is at the root of the tree
    if node.parent == nil:
        node.color = black
    else:
        insertCase2(tree, node)


proc insert*[T]( self: var RedBlackTree[T], values: varargs[T] ) =
    ## Adds a value to this tree
    for value in values:
        if self.root == nil:
            self.root = newNode(value)
            insertCase1(self, self.root)
        else:
            var inserted = insert[T](self.root, self.compare, value)
            insertCase1(self, inserted)

iterator items*[T]( tree: var RedBlackTree[T] ): T =
    ## Iterates over each value in a tree

    var current = leftmost(tree.root)
    while current != nil:
        yield current.value

        if current.right != nil:
            current = leftmost(current.right)
        else:
            while isRightChild(current):
                current = current.parent
            current = current.parent;

iterator reversed*[T]( tree: var RedBlackTree[T] ): T =
    ## Iterates over each value in a tree in reverse order

    var current = rightmost(tree.root)
    while current != nil:
        yield current.value

        if current.left != nil:
            current = rightmost(current.left)
        else:
            while isLeftChild(current):
                current = current.parent
            current = current.parent;

proc contains*[T]( tree: var RedBlackTree[T], value: T ): bool =
    ## Returns whether this tree contains the specific element
    var examine = tree.root
    while examine != nil:
        if examine.value == value:
            return true
        elif tree.compare(value, examine.value) <= 0:
            examine = examine.left
        else:
            examine = examine.right
    return false

proc min*[T]( tree: RedBlackTree[T] ): Option[T] =
    ## Returns the minimum value in a tree
    if tree.root == nil:
        return None[T]()
    else:
        return Some[T]( leftmost(tree.root).value )

proc max*[T]( tree: RedBlackTree[T] ): Option[T] =
    ## Returns the minimum value in a tree
    if tree.root == nil:
        return None[T]()
    else:
        return Some[T]( rightmost(tree.root).value )

