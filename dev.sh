#!/usr/bin/env bash
#
# Local development launcher for the ERP monolith.
#
# Starts the Flask backend (port 3004) and the Vite frontend (port 5173).
# The app reads os.environ directly (no python-dotenv), so this script
# exports the vars from .env before launching.
#
# Usage:
#   ./dev.sh          # start backend + frontend
#   ./dev.sh backend  # start backend only
#   ./dev.sh frontend # start frontend only
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "error: .env not found. Copy .env.example and configure DB_* vars." >&2
  exit 1
fi

start_backend() {
  echo "Starting backend on http://localhost:3004 ..."
  cd "$ROOT/src"
  set -a; . "$ROOT/.env"; set +a
  exec "$ROOT/.venv/bin/python" app.py
}

start_frontend() {
  echo "Starting frontend on http://localhost:5173 ..."
  cd "$ROOT/frontend"
  exec npm run dev
}

case "${1:-all}" in
  backend)  start_backend ;;
  frontend) start_frontend ;;
  all)
    # Run backend in the background, frontend in the foreground.
    # Ctrl+C stops both.
    ( start_backend ) &
    BACKEND_PID=$!
    trap 'kill "$BACKEND_PID" 2>/dev/null || true' EXIT INT TERM
    start_frontend
    ;;
  *)
    echo "usage: ./dev.sh [backend|frontend|all]" >&2
    exit 1
    ;;
esac
