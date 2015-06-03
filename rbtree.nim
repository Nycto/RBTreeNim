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

proc find[T]( tree: RedBlackTree[T], value: T ): Node[T] =
    ## Find a value in the tree and returns the containing node. Or nil
    var examine = tree.root
    while examine != nil:
        if examine.value == value:
            return examine
        elif tree.compare(value, examine.value) <= 0:
            examine = examine.left
        else:
            examine = examine.right
    return nil



proc newNode[T]( value: T, parent: Node[T] = nil ): Node[T] {.inline.} =
    return Node[T](
        left: nil, right: nil, parent: parent, color: red, value: value )

proc insert[T](
    self: var Node[T], compare: proc(a, b: T): int, value: T
): Node[T] =
    ## Does a basic binary search tree insert, returning the new node
    if compare(value, self.value) < 0:
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


template rotate( direction: expr, opposite: expr ) {.immediate.} =
    ## Rotates a node into its parents position

    var parent = node.parent
    if parent == nil:
        return

    # It looks like nim is trying to garbage collect this node before it's
    # actually gone for some reason. This is a hack to get around that
    var saved = node

    var grandparent = parent.parent
    var child = saved.`direction`

    # Move the child over
    parent.`opposite` = child
    if child != nil:
        child.parent = parent

    # Move the parent around
    saved.`direction` = parent
    parent.parent = saved

    # Move the node itself
    saved.parent = grandparent

    # Update the grandparent, swapping the root of the tree if needed
    if grandparent == nil:
        tree.root = saved
    elif grandparent.left == parent:
        grandparent.left = saved
    else:
        grandparent.right = saved

proc rotateLeft[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Rotates a node to the left
    rotate(left, right)

proc rotateRight[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Rotates a node to the right
    rotate(right, left)


template isOn[T]( self: Node[T], side: expr ): bool =
    ## Whether this node is the right child of its parent
    self.parent != nil and self.parent.`side` == self

proc isRed[T]( node: Node[T] ): bool {.inline.} =
    ## Safely checks whether a value is a red node or not
    return node != nil and node.color == red

proc isBlack[T]( node: Node[T] ): bool {.inline.} =
    ## Safely checks whether a node is black
    return node == nil or node.color == black

proc isAllBlack[T]( node: Node[T] ): bool {.inline.} =
    ## Safely checks if a node and its children are all black
    return node.isBlack and node.left.isBlack and node.right.isBlack

template far[T]( node: Node[T], direction: expr ): Node[T] =
    ## Walks every child in a specific direction down to the bottom
    var result = node
    while result != nil and result.`direction` != nil:
        result = result.`direction`
    result # implicit return

proc sibling[T]( node: Node[T] ): Node[T] {.inline.} =
    ## Returns the other child of the parent of this node
    if node.isOn(left): node.parent.right else: node.parent.left

proc replace[T]( tree: var RedBlackTree[T], node, replacement: var Node[T] ) =
    ## Replaces a node with another node
    if node.parent == nil:
        tree.root = replacement
    else:
        if node.isOn(left):
            node.parent.left = replacement
        else:
            node.parent.right = replacement

    if replacement != nil:
        replacement.parent = node.parent


proc insertCase1[T]( tree: var RedBlackTree[T], node: var Node[T] )

proc insertCase5[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 5: The parent P is red but the uncle U is black, the current node N
    ## is the left child of P, and P is the left child of its parent G
    var grandparent = grandparent(node)
    node.parent.color = black
    grandparent.color = red
    if node.isOn(left):
        rotateRight(tree, node.parent)
    else:
        rotateLeft(tree, node.parent)

proc insertCase4[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 4: The parent P is red but the uncle U is black; also, the current
    ## node N is the right child of P, and P in turn is the left child of its
    ## parent G
    if node.isOn(right) and node.parent.isOn(left):
        rotateLeft(tree, node)
        insertCase5(tree, node.left)
    elif node.isOn(left) and node.parent.isOn(right):
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
    if uncle.isRed:
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
    if not node.parent.isBlack:
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


proc deleteCase1[T]( tree: var RedBlackTree[T], node: var Node[T] )

proc deleteCase6[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 6: S is black, S's right child is red, and N is the left child of
    ## its parent P
    var sibling = node.sibling

    sibling.color = node.parent.color
    node.parent.color = black

    if node.isOn(left):
        sibling.right.color = black
        rotateLeft(tree, sibling)
    else:
        sibling.left.color = black
        rotateRight(tree, sibling)

proc deleteCase5[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 5: S is black, S's left child is red, S's right child is black, and
    ## N is the left child of its parent
    var sibling = node.sibling
    if sibling.isBlack:
        if node.isOn(left) and sibling.right.isBlack and sibling.left.isRed:
            sibling.color = red
            sibling.left.color = black
            rotateRight(tree, sibling.left)
        elif node.isOn(right) and sibling.right.isRed and sibling.left.isBlack:
            sibling.color = red
            sibling.right.color = black
            rotateLeft(tree, sibling.right)
    deleteCase6(tree, node)

proc deleteCase4[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 4: S and S's children are black, but P is red
    var sibling = node.sibling
    if node.parent.isRed and sibling.isAllBlack:
        sibling.color = red
        node.parent.color = black
    else:
        deleteCase5(tree, node)

proc deleteCase3[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 3: P, S, and S's children are black
    var sibling = node.sibling
    if node.parent.isBlack and sibling.isAllBlack:
        sibling.color = red
        deleteCase1(tree, node.parent)
    else:
        deleteCase4(tree, node)

proc deleteCase2[T]( tree: var RedBlackTree[T], node: var Node[T] ) {.inline.} =
    ## Case 2: The sibling is red

    var sibling = node.sibling

    if sibling.isRed:
        node.parent.color = red
        sibling.color = black
        if node.isOn(left):
            rotateLeft(tree, sibling)
        else:
            rotateRight(tree, sibling)

    deleteCase3(tree, node)

proc deleteCase1[T]( tree: var RedBlackTree[T], node: var Node[T] ) =
    ## Case 1: N is the new root
    if node.parent != nil:
        deleteCase2(tree, node)


proc findDeleteTarget[T]( node: Node[T] ): Node[T] {.inline.} =
    ## Deleting from a Red/Black tree starts by searching for a node with one
    ## or no children. We then swap the node being deleted with that node,
    ## and delete it from the tree. This function finds the node to swap with.
    ## Note that it could return the very node it was given
    if node.left == nil or node.right == nil:
        result = node
    else:
        result = node.left
        while result.right != nil:
            result = result.right

proc delete*[T]( self: var RedBlackTree[T], value: T ) =
    ## Deletes a value from the tree

    # Find the value we are being asked to delete
    var toDelete = find(self, value)
    if toDelete == nil:
        return

    # We can't delete a node with two children, so find a predecessor that has
    # 0 or 1 children that we can swap with the node we want to delete
    var target = findDeleteTarget(toDelete)
    if target != toDelete:
        swap(target.value, toDelete.value)

    # Precondition: At this point, we can guarantee that `target` contains the
    # value we want to delete and that it contains 0 or 1 child.
    assert(target.value == value)
    assert(target.left == nil or target.right == nil)

    var child = if target.right == nil: target.left else: target.right
    if target.isBlack:
        target.color = if child.isBlack: black else: red
        deleteCase1(self, target)

    replace(self, target, child)

    if self.root.isRed:
        self.root.color = black


template defineIter( low: expr, high: expr ) {.immediate.} =
    ## Defines the content of the `items` and `reversed` iterators

    var current = tree.root.far(low)
    while current != nil:
        yield current.value

        if current.`high` != nil:
            current = current.`high`.far(low)
        else:
            while current.isOn(high):
                current = current.parent
            current = current.parent

iterator items*[T]( tree: RedBlackTree[T] ): T =
    ## Iterates over each value in a tree
    defineIter(left, right)

iterator reversed*[T]( tree: RedBlackTree[T] ): T =
    ## Iterates over each value in a tree in reverse order
    defineIter(right, left)


proc contains*[T]( tree: RedBlackTree[T], value: T ): bool =
    ## Returns whether this tree contains the specific element
    return find(tree, value) != nil


template defineMinMax( direction: expr ) {.immediate.} =
    ## Defines the content of the min and max functions
    if tree.root == nil:
        return None[T]()
    else:
        return Some[T]( tree.root.far(direction).value )

proc min*[T]( tree: RedBlackTree[T] ): Option[T] =
    ## Returns the minimum value in a tree
    defineMinMax(left)

proc max*[T]( tree: RedBlackTree[T] ): Option[T] =
    ## Returns the minimum value in a tree
    defineMinMax(right)


proc validate[T]( node: Node[T] ): int =
    ## Raises an assertion exception if a node is corrupt. Returns the number
    ## of black nodes contained within this node (including this node)

    if node == nil:
        return 1

    let left = node.left
    let right = node.right

    # Consecutive red links
    if node.isRed and left.isRed:
        raise newException(AssertionError,
            "Red node ($1) contains another red node (left: $2)" % [
                $node.value, $left.value
            ])
    elif node.isRed and right.isRed:
        raise newException(AssertionError,
            "Red node ($1) contains another red node (right: $2)" % [
                $node.value, $right.value
            ])

    let leftHeight = validate(left)
    let rightHeight = validate(right)

    ## Invalid binary search tree
    if left != nil and left.value > node.value:
        raise newException(AssertionError,
            "Left node ($1) is greater than its parent ($2)" % [
                $left.value, $node.value
            ])

    if right != nil and right.value < node.value:
        raise newException(AssertionError,
            "Right node ($1) is less than its parent ($2)" % [
                $right.value, $node.value
            ])

    ## Black height mismatch
    if leftHeight != 0 and rightHeight != 0 and leftHeight != rightHeight:
        raise newException(AssertionError,
            "Imbalanced number of black nodes ($2 vs $3) beneath node ($1)" % [
                $node.value, $leftHeight, $rightHeight
            ])

    # return the total number of black nodes
    return leftHeight + (if node.isRed: 0 else: 1)

proc validate*[T]( tree: RedBlackTree[T] ) =
    ## Raises an assertion exception if a red/black tree is corrupt
    discard validate(tree.root)


