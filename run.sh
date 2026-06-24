#!/usr/bin/env bash
set -e

swiftc \
  -parse-as-library \
  -o CodexStatusMenuBar \
  CodexStatusMenuBar.swift \
  -framework AppKit

pkill -x CodexStatusMenuBar 2>/dev/null || true

./CodexStatusMenuBar &