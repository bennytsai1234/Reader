#!/usr/bin/env bash
set -euo pipefail

START="${1:-${SOURCE_START:-0}}"
LIMIT="${2:-${SOURCE_LIMIT:-10}}"
TIMEOUT_SECONDS="${SOURCE_TIMEOUT_SECONDS:-20}"

quickjs_lib="$(find "${HOME}/.pub-cache" -path '*flutter_js*/linux/shared/libquickjs_c_bridge_plugin.so' -print -quit 2>/dev/null || true)"
if [[ -n "${quickjs_lib}" ]]; then
  export LD_LIBRARY_PATH="$(dirname "${quickjs_lib}")${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

echo "[source-validation] start=${START} limit=${LIMIT}"
echo "[source-validation] timeout=${TIMEOUT_SECONDS}s"
if [[ -n "${quickjs_lib}" ]]; then
  echo "[source-validation] quickjs=$(dirname "${quickjs_lib}")"
else
  echo "[source-validation] quickjs=not-found"
fi

SOURCE_START="${START}" SOURCE_LIMIT="${LIMIT}" SOURCE_TIMEOUT_SECONDS="${TIMEOUT_SECONDS}" flutter test tool/source_batch_validation_test.dart
