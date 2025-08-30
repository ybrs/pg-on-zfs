.PHONY: run
run:
	python3 cmd/pgbranchd/main.py

.PHONY: lint
lint:
	python3 -m py_compile cmd/pgbranchd/main.py
