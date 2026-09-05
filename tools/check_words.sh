#!/bin/sh
# Self-check for the day→word mapping. Compiles the real Shared sources.
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)/wordcheck
swiftc -O -o "$out" OneWord/Shared/Word.swift OneWord/Shared/WordProvider.swift \
    OneWord/Shared/SavedWords.swift OneWord/Shared/WordSelectionStore.swift OneWord/Shared/AppGroup.swift \
    tools/WordProviderCheck.swift
"$out"
