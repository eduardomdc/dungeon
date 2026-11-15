#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "client" && "${1:-}" != "server" ]]; then
  echo "Usage: $0 {client|server} [--debug|--release] [--] [arguments...]" >&2
  exit 1
fi
target="$1"
shift

# Default to debug builds; select the mode immediately after the target.
build_flags=(-debug -o:none)
case "${1:-}" in
  --debug)
    shift
    ;;
  --release)
    build_flags=(-o:speed)
    shift
    ;;
esac
if [[ "${1:-}" == "--" ]]; then
  shift
fi

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_root"

mkdir -p bin
odin build "src/$target" "-out:bin/$target" "${build_flags[@]}"
exec "$project_root/bin/$target" "$@"
