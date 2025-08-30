.PHONY: snapshot drop
snapshot:
	python3 cmd/pgbranchd/main.py snapshot $(SRC) $(DST)
drop:
	python3 cmd/pgbranchd/main.py drop $(DB)
