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

        # The root of the tree
        root: Node[T]


proc newRBTree*[T](): RedBlackTree[T] =
  # Creates a new Red/Black tree
  return RedBlackTree[T]( root: nil )

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

proc insertCase1[T]( node: var Node[T] ) =
    ## Case 1: The current node N is at the root of the tree
    if node.parent == nil:
        node.color = black

proc insert*[T]( self: var RedBlackTree[T], value: T ) =
    ## Adds a value to this tree
    if self.root == nil:
        self.root = newNode(value)
        insertCase1(self.root)

