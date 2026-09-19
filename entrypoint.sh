#!/bin/sh
set -eu

is_true() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON|On) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_true "${USE_SQLITE:-false}"; then
  if [ -z "${HOST:-}" ] || [ -z "${PORT:-}" ]; then
    echo "HOST and PORT must be set for PostgreSQL"
    exit 1
  fi

  echo "Waiting for database at ${HOST}:${PORT}..."
  until nc -z "${HOST}" "${PORT}"; do
    sleep 1
  done
  echo "Database is ready"
fi

if is_true "${RUN_MIGRATIONS:-true}"; then
  python manage.py migrate --noinput
fi

exec gunicorn core.wsgi:application \
  --bind "0.0.0.0:${APP_PORT:-8000}" \
  --workers "${GUNICORN_WORKERS:-2}" \
  --threads "${GUNICORN_THREADS:-2}" \
  --timeout "${GUNICORN_TIMEOUT:-120}" \
  --access-logfile - \
  --error-logfile -
