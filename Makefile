
# Generates documentation for mainline
.PHONY: doc
doc:
	$(eval HASH := $(shell git rev-parse master))
	git show $(HASH):rbtree.nim > rbtree.nim
	nim doc rbtree.nim
	git add rbtree.html
	git commit -m "Generate docs from $(HASH)"

