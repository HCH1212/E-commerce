#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="${ROOT_DIR}/tmp/pids"
KEEP_DOCKER=0
NO_FORCE=0

SERVICES=(
  eino
  casbin
  email
  checkout
  payment
  order
  cart
  user
  product
  frontend
)

usage() {
  cat <<'EOF'
Usage: ./stop_all.sh [options]

Options:
  --keep-docker  Stop only Go services, keep docker containers
  --no-force     Do not use SIGKILL fallback
  -h, --help     Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keep-docker)
        KEEP_DOCKER=1
        ;;
      --no-force)
        NO_FORCE=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "ERROR: unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

is_pid_alive() {
  local pid="$1"
  kill -0 "${pid}" >/dev/null 2>&1
}

stop_pid() {
  local pid="$1"
  if ! is_pid_alive "${pid}"; then
    return 0
  fi

  kill "${pid}" >/dev/null 2>&1 || true
  for _ in {1..10}; do
    if ! is_pid_alive "${pid}"; then
      return 0
    fi
    sleep 1
  done

  if [[ "${NO_FORCE}" -eq 0 ]]; then
    kill -9 "${pid}" >/dev/null 2>&1 || true
  fi
}

stop_service_by_name_fallback() {
  local svc="$1"
  pkill -f "app/${svc}" >/dev/null 2>&1 || true
  pkill -f "${ROOT_DIR}/app/${svc}" >/dev/null 2>&1 || true
}

stop_service() {
  local svc="$1"
  local pid_file="${PID_DIR}/${svc}.pid"

  if [[ ! -f "${pid_file}" ]]; then
    echo "INFO: ${svc} pid file not found, skip."
    stop_service_by_name_fallback "${svc}"
    return 0
  fi

  local pid
  pid="$(cat "${pid_file}")"
  if [[ -z "${pid}" ]]; then
    rm -f "${pid_file}"
    echo "INFO: ${svc} pid file is empty, skip."
    stop_service_by_name_fallback "${svc}"
    return 0
  fi

  stop_pid "${pid}"
  if is_pid_alive "${pid}"; then
    echo "WARNING: ${svc} still alive (pid=${pid})."
  fi
  rm -f "${pid_file}"
  echo "OK: ${svc} stopped."
}

main() {
  parse_args "$@"

  echo "========================================"
  echo "  E-commerce one-click stop (Linux)"
  echo "========================================"

  for svc in "${SERVICES[@]}"; do
    stop_service "${svc}"
  done

  if [[ "${KEEP_DOCKER}" -eq 1 ]]; then
    echo "INFO: keep docker containers running."
  else
    echo "Stopping docker compose services..."
    docker compose down || true
  fi

  echo "All services stopped."
}

main "$@"
