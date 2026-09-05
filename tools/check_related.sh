#!/bin/sh
# Self-check for the related-words index. Compiles the real sources.
# NOTE: RelatedWords.swift lives in OneWord/, not OneWord/Shared/ (app-only file).
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)/relatedcheck
swiftc -O -o "$out" OneWord/Models/RelatedWords.swift OneWord/Shared/Word.swift \
    OneWord/Shared/WordProvider.swift OneWord/Shared/SavedWords.swift \
    OneWord/Shared/WordSelectionStore.swift OneWord/Shared/AppGroup.swift \
    tools/RelatedWordsCheck.swift
"$out"
