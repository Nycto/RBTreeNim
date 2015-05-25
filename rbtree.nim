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
        return "()"
    else:
        return "(%s: %s)" % [
            if self.color == red: "R" else: "B",
            $(self.value),
            if self.left != nil or self.right != nil:
                " " & $(self.left) & " " & $(self.right)
            else:
                ""
        ]

proc `$`* [T]( self: RedBlackTree[T] ): string =
    ## Returns a tree as a string
    return "RedBlackTree" & `$`[T](self.root)

