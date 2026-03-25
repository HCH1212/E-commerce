#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${ROOT_DIR}/tmp/logs"
PID_DIR="${ROOT_DIR}/tmp/pids"
MYSQL_SERVICE="mysql"

SERVICES=(
  frontend
  product
  user
  cart
  order
  payment
  checkout
  email
  casbin
  eino
)

MYSQL_USER="root"
MYSQL_PASSWORD="041212"

SKIP_DOCKER=0
SKIP_INIT=0
SKIP_PRODUCT_INIT=0
ONLY_INFRA=0

usage() {
  cat <<'EOF'
Usage: ./start_all.sh [options]

Options:
  --skip-docker        Skip `docker compose up -d`
  --skip-init          Skip init_databases.sql
  --skip-product-init  Skip app/product/default.sql
  --only-infra         Start docker + db init only, do not start Go services
  -h, --help           Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-docker)
        SKIP_DOCKER=1
        ;;
      --skip-init)
        SKIP_INIT=1
        ;;
      --skip-product-init)
        SKIP_PRODUCT_INIT=1
        ;;
      --only-infra)
        ONLY_INFRA=1
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

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: '${cmd}' is required but not installed."
    exit 1
  fi
}

is_pid_alive() {
  local pid="$1"
  kill -0 "${pid}" >/dev/null 2>&1
}

start_service() {
  local svc="$1"
  local svc_dir="${ROOT_DIR}/app/${svc}"
  local log_file="${LOG_DIR}/${svc}.log"
  local pid_file="${PID_DIR}/${svc}.pid"

  if [[ ! -d "${svc_dir}" ]]; then
    echo "ERROR: service directory not found: ${svc_dir}"
    return 1
  fi

  if [[ -f "${pid_file}" ]]; then
    local old_pid
    old_pid="$(cat "${pid_file}")"
    if [[ -n "${old_pid}" ]] && is_pid_alive "${old_pid}"; then
      echo "INFO: ${svc} is already running (pid=${old_pid}), skip."
      return 0
    fi
    rm -f "${pid_file}"
  fi

  (
    cd "${svc_dir}"
    nohup go run . >"${log_file}" 2>&1 &
    echo $! >"${pid_file}"
  )

  sleep 2

  local pid
  pid="$(cat "${pid_file}")"
  if is_pid_alive "${pid}"; then
    echo "OK: ${svc} started (pid=${pid})"
  else
    echo "ERROR: ${svc} failed to start. Check log: ${log_file}"
    return 1
  fi
}

wait_mysql_ready() {
  local retries=60
  local wait_seconds=2
  local i

  echo "Waiting for MySQL to be ready..."
  for ((i = 1; i <= retries; i++)); do
    if docker compose exec -T "${MYSQL_SERVICE}" mysqladmin ping -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent >/dev/null 2>&1; then
      echo "OK: MySQL is ready."
      return 0
    fi
    sleep "${wait_seconds}"
  done

  echo "ERROR: MySQL is not ready after $((retries * wait_seconds)) seconds."
  exit 1
}

run_sql_file() {
  local sql_file="$1"
  if [[ ! -f "${sql_file}" ]]; then
    echo "ERROR: SQL file not found: ${sql_file}"
    exit 1
  fi

  cat "${sql_file}" | docker compose exec -T "${MYSQL_SERVICE}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}"
}

print_last_log_hint() {
  local svc="$1"
  local log_file="${LOG_DIR}/${svc}.log"
  if [[ -f "${log_file}" ]]; then
    echo "----- ${svc}.log (last 20 lines) -----"
    tail -n 20 "${log_file}" || true
    echo "--------------------------------------"
  fi
}

main() {
  parse_args "$@"

  require_cmd docker
  require_cmd go
  require_cmd nohup

  mkdir -p "${LOG_DIR}" "${PID_DIR}"

  echo "========================================"
  echo "  E-commerce one-click start (Linux)"
  echo "========================================"

  if [[ "${SKIP_DOCKER}" -eq 0 ]]; then
    echo "[1/5] Starting Docker base services..."
    docker compose up -d
  else
    echo "[1/5] Skipped Docker startup."
  fi

  echo "[2/5] Waiting for MySQL (${MYSQL_SERVICE})..."
  wait_mysql_ready

  if [[ "${SKIP_INIT}" -eq 0 ]]; then
    echo "[3/5] Initializing databases..."
    run_sql_file "${ROOT_DIR}/init_databases.sql"
  else
    echo "[3/5] Skipped database init."
  fi

  if [[ "${SKIP_PRODUCT_INIT}" -eq 0 ]]; then
    echo "[4/5] Initializing product data..."
    if run_sql_file "${ROOT_DIR}/app/product/default.sql"; then
      echo "OK: product data initialized."
    else
      echo "WARNING: product data initialization failed, continue."
    fi
  else
    echo "[4/5] Skipped product data init."
  fi

  if [[ "${ONLY_INFRA}" -eq 1 ]]; then
    echo "[5/5] Skipped app services (--only-infra)."
    echo "Infra is ready."
    exit 0
  fi

  echo "[5/5] Starting all app services..."
  for svc in "${SERVICES[@]}"; do
    if ! start_service "${svc}"; then
      print_last_log_hint "${svc}"
      exit 1
    fi
  done

  echo
  echo "All services started."
  echo "Frontend: http://localhost:8080"
  echo "Consul:   http://localhost:8500"
  echo "Logs:     ${LOG_DIR}"
  echo "PIDs:     ${PID_DIR}"
  echo
  echo "Use './stop_all.sh' to stop everything."
}

main "$@"
