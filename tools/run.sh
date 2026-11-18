
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "client" && "${1:-}" != "server" && "${1:-}" != "link" ]]; then
  echo "Usage: $0 {client|server|link} [--debug|--release] [--] [arguments...]" >&2
  exit 1
fi

target="$1"
shift

# Default to debug builds
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

# --------------------------------------------------
# Steamworks setup
# --------------------------------------------------

steam_bin="ext/steamworks/redistributable_bin"

case "$(uname -s)" in
  Linux)
    steam_lib="$steam_bin/linux64/libsteam_api.so"
    ;;
  Darwin)
    steam_lib="$steam_bin/osx/libsteam_api.dylib"
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$steam_lib" ]]; then
  echo "Steamworks library not found: $steam_lib" >&2
  exit 1
fi

cp "$steam_lib" bin/

# Create steam_appid.txt if it doesn't exist
if [[ ! -f bin/steam_appid.txt ]]; then
  echo 480 > bin/steam_appid.txt
fi

# --------------------------------------------------
# Build and run
# --------------------------------------------------

if [[ "$target" == "link" ]]; then
  odin build src/server -out:bin/server "${build_flags[@]}"
  odin build src/client -out:bin/client "${build_flags[@]}"

  "$project_root/bin/server" "$@" &
  server_pid=$!

  cleanup() {
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  }
  trap cleanup EXIT INT TERM

  set +e
  "$project_root/bin/client" "$@"
  client_status=$?
  set -e

  exit "$client_status"
else
  odin build "src/$target" "-out:bin/$target" "${build_flags[@]}"
  exec "$project_root/bin/$target" "$@"
fi
