##
## A red/black binary search tree
##

import strutils, options, ropes

type
    Color = enum ## The color of a node
        red, black

    TreeElem* = concept e
        ## An individual element stored in a RedBlackTree
        cmp(e, e) is int

    Node[T] = ref object ## A node within a red/black tree

        # The (potential) connections in this node
        left, right, parent: Node[T]

        # The color of this node
        color: Color

        # The  value of this node
        value: T

    RedBlackTree*[T, K] = object ## A Red/Black tree
        ## * `T` is the type of value being stored
        ## * `K` is the type of key used to index those values

        # The root of the tree
        root: Node[T]


template defineIndex*(
    name: typedesc, source: typedesc,
    extractIt: expr, cmpAB: expr
) {.immediate.} =
    ## Defines a distinct type with custom extract and cmp methods. This
    ## makes it easy to index the same data in different ways. It also defines
    ## converters to make the new type fairly transparent.
    ## * `name`: The name of the type to define
    ## * `source`: The type to derive from. This is done via `distinct`
    ## * `extractIt`: The body of the `extract` function. There will be a
    ##   variable named `it` defined that is the value from which a key
    ##   needs to be pulled.
    ## * `cmpAB`: The body of the `cmp` function. There will be two variables
    ##   named `a` and `b` defined. These are the arguments to the `cmp` proc
    ##   that need to be compared.

    type name* {.borrow: `.`.} = distinct source

    converter convert*( i: name ): source = source(i)

    converter convert*( i: source ): name = name(i)

    proc cmp*( arg1, arg2: name ): int =
        let a {.inject.} = arg1
        let b {.inject.} = arg2
        return cmpAB

    proc extract*( arg: name ): auto =
        let it {.inject.} = arg
        return extractIt

    # Converters don't work with `varargs`, so define a custom insert that
    # makes it easier to add multiple values of the custom type
    proc insert*[K](
        self: var RedBlackTree[name, K],
        one: source, two: source,
        more: varargs[source]
    ) =
        insert[name, K](self, one)
        insert[name, K](self, two)
        for val in more:
            insert[name, K](self, val)


proc newRBTree*[T: TreeElem, K](): RedBlackTree[T, K] =
    ## Creates a new Red/Black tree
    RedBlackTree[T, K]( root: nil )

proc `$` [T]( accum: var Rope, self: Node[T] ) =
    ## Converts a node to a string
    if self == nil:
        accum.add("()")
    else:
        accum.add("(")
        accum.add(if self.color == red: "R" else: "B")
        accum.add(" ")
        accum.add($(self.value))
        if self.left != nil or self.right != nil:
            accum.add(" ")
            `$`(accum, self.left)
            accum.add(" ")
            `$`(accum, self.right)
        accum.add(")")

proc `$`[T]( node: Node[T] ): string =
    ## Returns a node as a string
    var accum = rope("")
    `$`(accum, node)
    return $accum

proc `$`* [T: TreeElem, K]( self: RedBlackTree[T, K] ): string =
    ## Returns a tree as a string
    var accum = rope("RedBlackTree")
    accum.add(`$`(self.root))
    return $accum


template getKey( typeT, typeK: typedesc, value: expr ): expr =
    ## Extracts the key from the given value. This is smart enough to not call
    ## `extract` a value is both the key and value
    when typeK is typeT and not compiles(value.extract):
        value
    else:
        value.extract

template compareKeys( a, b: TreeElem ): int =
    ## Compares two keys
    # This was originally more complex. It probably doesn't need to be its own
    # function at this point, but I'm leaving this in place in case it needs
    # to become more complicated
    a.cmp(b)

proc search[T, K]( tree: RedBlackTree[T, K], key: K ): Node[T] =
    ## Find a value in the tree and returns the containing node. Or nil
    var examine = tree.root
    while examine != nil:
        let nodeKey = getKey(T, K, examine.value)
        if nodeKey == key:
            return examine
        elif compareKeys(key, nodeKey) <= 0:
            examine = examine.left
        else:
            examine = examine.right
    return nil



proc newNode[T]( value: T, parent: Node[T] = nil ): Node[T] {.inline.} =
    return Node[T](
        left: nil, right: nil, parent: parent, color: red, value: value )

proc insert[T, K](
    tree: RedBlackTree[T, K], self: var Node[T], value: T
): Node[T] =
    ## Does a basic binary search tree insert, returning the new node
    if compareKeys(getKey(T, K, value), getKey(T, K, self.value)) < 0:
        if self.left == nil:
            result = newNode( value, self )
            self.left = result
        else:
            result = insert(tree, self.left, value)
    else:
        if self.right == nil:
            result = newNode( value, self )
            self.right = result
        else:
            result = insert(tree, self.right, value)

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


template rotate[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T],
    direction: expr, opposite: expr
) =
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

proc rotateLeft[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Rotates a node to the left
    rotate(tree, node, left, right)

proc rotateRight[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Rotates a node to the right
    rotate(tree, node, right, left)


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

proc replace[T, K](
    tree: var RedBlackTree[T, K], node, replacement: var Node[T]
) =
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


proc insertCase1[T, K]( tree: var RedBlackTree[T, K], node: var Node[T] )

proc insertCase5[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Case 5: The parent P is red but the uncle U is black, the current node N
    ## is the left child of P, and P is the left child of its parent G
    var grandparent = grandparent(node)
    node.parent.color = black
    grandparent.color = red
    if node.isOn(left):
        rotateRight(tree, node.parent)
    else:
        rotateLeft(tree, node.parent)

proc insertCase4[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
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

proc insertCase3[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
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

proc insertCase2[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Case 2: The current node's parent P is black, so both children of every
    ## red node are black
    if not node.parent.isBlack:
        insertCase3(tree, node)

proc insertCase1[T, K]( tree: var RedBlackTree[T, K], node: var Node[T] ) =
    ## Case 1: The current node N is at the root of the tree
    if node.parent == nil:
        node.color = black
    else:
        insertCase2(tree, node)


proc insert*[T: TreeElem, K]( self: var RedBlackTree[T, K], value: T ) =
    ## Adds a value to this tree
    if self.root == nil:
        self.root = newNode(value)
        insertCase1(self, self.root)
    else:
        var inserted = insert(self, self.root, value)
        insertCase1(self, inserted)

proc insert*[T: TreeElem, K](
    self: var RedBlackTree[T, K], one: T, two: T, more: varargs[T]
) =
    ## Adds multiple values to this tree
    insert(self, one)
    insert(self, two)
    for value in more:
        insert(self, value)


proc deleteCase1[T, K]( tree: var RedBlackTree[T, K], node: var Node[T] )

proc deleteCase6[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
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

proc deleteCase5[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
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

proc deleteCase4[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Case 4: S and S's children are black, but P is red
    var sibling = node.sibling
    if node.parent.isRed and sibling.isAllBlack:
        sibling.color = red
        node.parent.color = black
    else:
        deleteCase5(tree, node)

proc deleteCase3[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
    ## Case 3: P, S, and S's children are black
    var sibling = node.sibling
    if node.parent.isBlack and sibling.isAllBlack:
        sibling.color = red
        deleteCase1(tree, node.parent)
    else:
        deleteCase4(tree, node)

proc deleteCase2[T, K](
    tree: var RedBlackTree[T, K], node: var Node[T]
) {.inline.} =
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

proc deleteCase1[T, K]( tree: var RedBlackTree[T, K], node: var Node[T] ) =
    ## Case 1: N is the new root
    if node.parent != nil:
        deleteCase2(tree, node)


proc findDeleteTarget[T]( node: Node[T] ): Node[T] {.inline.} =
    ## Deleting from a Red/Black tree starts by searching for a node with one
    ## or no children. We then swap the node being deleted with that node,
    ## and delete it from the tree. This function finds the node to swap with.
    ## Note that it could return the very node it was given
    if node.left == nil:
        if node.right == nil:
            return node
        else:
            return node.right.far(left)
    else:
        return node.left.far(right)

proc delete*[T: TreeElem, K]( self: var RedBlackTree[T, K], value: T ) =
    ## Deletes a value from the tree

    # Find the value we are being asked to delete
    var toDelete = search(self, value)
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


template defineIter[T, K]( tree: RedBlackTree[T, K], low: expr, high: expr ) =
    ## Defines the content of the `items` and `reversed` iterators

    var current = far(tree.root, low)
    while current != nil:
        yield current.value

        if current.`high` != nil:
            current = far(current.`high`, low)
        else:
            while isOn(current, high):
                current = current.parent
            current = current.parent

iterator items*[T: TreeElem, K]( tree: RedBlackTree[T, K] ): T =
    ## Iterates over each value in a tree
    defineIter(tree, left, right)

iterator reversed*[T: TreeElem, K]( tree: RedBlackTree[T, K] ): T =
    ## Iterates over each value in a tree in reverse order
    defineIter(tree, right, left)


proc contains*[T: TreeElem, K]( tree: RedBlackTree[T, K], value: T|K ): bool =
    ## Returns whether this tree contains the specific value or key
    when value is K:
        return search(tree, value) != nil
    else:
        let found = search(tree, getKey(T, K, value))
        return found != nil and found.value == value

proc find*[T: TreeElem, K]( tree: RedBlackTree[T, K], key: K ): Option[T] =
    ## Searches for a value by its key
    let found = search(tree, key)
    return if found == nil: none(T) else: some[T](found.value)


template defineMinMax[T, K]( tree: RedBlackTree[T, K], direction: expr ) =
    ## Defines the content of the min and max functions
    if tree.root == nil:
        return none(T)
    else:
        return some[T]( far(tree.root, direction).value )

proc min*[T: TreeElem, K]( tree: RedBlackTree[T, K] ): Option[T] =
    ## Returns the minimum value in a tree
    tree.defineMinMax(left)

proc max*[T: TreeElem, K]( tree: RedBlackTree[T, K] ): Option[T] =
    ## Returns the minimum value in a tree
    tree.defineMinMax(right)



template defineCeilFloor[T, K](
    tree: RedBlackTree[T, K], key: K,
    compare: expr, overUnderBranch: expr, inRangeBranch: expr
) =
    ## Constructs the body of the `ceil` and `floor` functions

    proc walk(node: Node[T]): Node[T] =
        ## Traverses the given node for the search value. This will return nil
        ## if there isn't a value in this tree that matches the appropriate
        ## constraints.

        if node == nil:
            return nil

        let compared = compareKeys(getKey(T, K, node.value), key)

        if compared == 0:
            return node
        elif `compare`(compared, 0):
            return walk(node.`overUnderBranch`)

        let branch = walk(node.`inRangeBranch`)

        if branch == nil:
            return node
        elif `compare`(compareKeys(getKey(T, K, branch.value), key), 0):
            return node
        else:
            return branch

    let node = walk(tree.root)
    return if node == nil: none(T) else: some[T](node.value)

proc ceil*[T: TreeElem, K]( tree: RedBlackTree[T, K], key: K ): Option[T] =
    ## Returns the value in this tree that is equal to or just greater than
    ## the given value
    proc lessThan(a, b: int): bool {.inline.} = a < b
    defineCeilFloor(tree, key, lessThan, right, left)

proc floor*[T: TreeElem, K]( tree: RedBlackTree[T, K], key: K ): Option[T] =
    ## Returns the value in this tree that is equal to or just less than
    ## the given value
    proc greaterThan(a, b: int): bool {.inline.} = a > b
    defineCeilFloor(tree, key, greaterThan, left, right)


proc isEmpty*[T: TreeElem, K]( tree: RedBlackTree[T, K] ): bool =
    ## Returns whether this tree is empty of any nodes
    return tree.root == nil


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

proc validate*[T: TreeElem, K]( tree: RedBlackTree[T, K] ) =
    ## Raises an assertion exception if a red/black tree is corrupt. This is
    ## primarily for testing purposes and isn't something you should need to
    ## call from an application.
    discard validate(tree.root)


