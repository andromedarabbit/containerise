SHELL := /bin/bash
OUTPUT=containerise.txt
OUTPUT_PUBLIC_ONLY=containerise-public.txt

ENC_RECORDS = $(shell find records-enc -type f -and \( -name '*.enc' -or -name '*.enc.*' \) -not -path ".")
RECORDS = $(shell find records-enc -type f -not \( -name '*.enc' -or -name '*.enc.*' \) -not -path ".")

default: build

.PHONY: help
help:
	@ echo "make decrypt"
	@ echo "make encrypt"
	@ echo "make build"

.PHONY: prepare
prepare:
	@ [[ -d node_modules ]] || npm install
	@ ( type sops &>/dev/null ) || brew install sops

.PHONY: decrypt
decrypt: prepare
	@ for FILE in $(ENC_RECORDS); do \
		DIRNAME="$$(dirname $${FILE})"; \
		FILENAME="$$(basename $${FILE})"; \
		TARGET_FILENAME=$${FILENAME//.enc/}; \
		sops -d "$${FILE}" > "$${DIRNAME}/$${TARGET_FILENAME}"; \
	done

.PHONY: encrypt
encrypt: prepare
	@ for FILE in $(RECORDS); do \
		DIRNAME="$$(dirname $${FILE})"; \
		FILENAME="$$(basename $${FILE})"; \
		EXTENSION=".$${FILENAME##*.}"; \
		FILENAME="$${FILENAME%.*}"; \
		TARGET_FILENAME="$${FILENAME}.enc$${EXTENSION}"; \
		sops -e "$${FILE}" > "$${DIRNAME}/$${TARGET_FILENAME}"; \
	done

.PHONY: build
build: decrypt
	grep -v -e '^!' -h records/*.txt | sed 's/[[:space:]]*$$//' | grep '\S'  | sort -u | tee $(OUTPUT_PUBLIC_ONLY)
	@ git add $(OUTPUT_PUBLIC_ONLY)

	@ [[ -f $(OUTPUT) ]] && rm -f $(OUTPUT)
	@ cp $(OUTPUT_PUBLIC_ONLY) $(OUTPUT)
	@ for FILE in $(RECORDS); do \
		grep -v -e '^!' -h $${FILE} | sed 's/[[:space:]]*$$//' | grep '\S'  | sort -u | tee -a $(OUTPUT) ; \
	done
