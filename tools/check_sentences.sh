#!/bin/sh
# Self-check for the practice corpus and the reel's draw.
# NOTE: Sentences.swift lives in OneWord/Models/, not Shared/ (app-only, widget never reads it).
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)/sentencecheck
swiftc -O -o "$out" OneWord/Models/Sentences.swift tools/SentencesCheck.swift
"$out"
