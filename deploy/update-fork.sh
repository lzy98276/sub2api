#!/usr/bin/env bash
# Update Sub2API from the fork while retaining all deployed data.
set -Eeuo pipefail

DEPLOY_DIR="${SUB2API_DEPLOY_DIR:-/root/sub2api-deploy}"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
REPOSITORY="${SUB2API_REPOSITORY:-lzy98276/sub2api}"
REVISION="${1:-${SUB2API_REF:-main}}"
BACKUP_ROOT="${SUB2API_BACKUP_DIR:-/root/sub2api-backups}"
LOCK_FILE="/var/lock/sub2api-fork-update.lock"
WORK_DIR=""
PREVIOUS_IMAGE=""
DEPLOYMENT_STARTED=false

if [[ ! "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "SUB2API_REPOSITORY must be an owner/repository value." >&2
  exit 2
fi

if [[ ! "$REVISION" =~ ^[A-Za-z0-9._/-]+$ ]]; then
  echo "Revision may contain only letters, numbers, dots, underscores, slashes, and hyphens." >&2
  exit 2
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Compose file not found: $COMPOSE_FILE" >&2
  exit 2
fi

if ! command -v docker >/dev/null || ! command -v curl >/dev/null || ! command -v tar >/dev/null || ! command -v flock >/dev/null; then
  echo "docker, curl, tar, and flock are required." >&2
  exit 2
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Another Sub2API update is already running." >&2
  exit 1
fi

compose() {
  docker compose --project-directory "$DEPLOY_DIR" -f "$COMPOSE_FILE" "$@"
}

rollback() {
  if [[ "$DEPLOYMENT_STARTED" != true || -z "$PREVIOUS_IMAGE" ]]; then
    return
  fi

  echo "Update failed. Restoring the previous application image: $PREVIOUS_IMAGE" >&2
  SUB2API_IMAGE="$PREVIOUS_IMAGE" compose up -d --no-deps --force-recreate sub2api || true
}

cleanup() {
  local status=$?
  if ((status != 0)); then
    rollback
  fi
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
  exit "$status"
}

trap cleanup EXIT

CURRENT_CONTAINER="$(compose ps -q sub2api)"
if [[ -z "$CURRENT_CONTAINER" ]]; then
  echo "The current Sub2API container is not running." >&2
  exit 1
fi
PREVIOUS_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$CURRENT_CONTAINER")"

BACKUP_DIR="$BACKUP_ROOT/sub2api-$(date -u +%Y%m%dT%H%M%SZ)"
umask 077
mkdir -p "$BACKUP_DIR"
cp "$COMPOSE_FILE" "$BACKUP_DIR/docker-compose.yml"
cp "$DEPLOY_DIR/.env" "$BACKUP_DIR/.env"

POSTGRES_CONTAINER="$(compose ps -q postgres)"
if [[ -z "$POSTGRES_CONTAINER" ]]; then
  echo "The Postgres container is not running." >&2
  exit 1
fi

echo "Creating database and application-data backups in $BACKUP_DIR"
docker exec "$POSTGRES_CONTAINER" sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip -c > "$BACKUP_DIR/database.sql.gz"
tar -C "$DEPLOY_DIR" -czf "$BACKUP_DIR/application-and-redis-data.tgz" data redis_data
sha256sum "$BACKUP_DIR/database.sql.gz" "$BACKUP_DIR/application-and-redis-data.tgz" > "$BACKUP_DIR/SHA256SUMS"

WORK_DIR="$(mktemp -d /root/.sub2api-fork-build.XXXXXX)"
ARCHIVE="$WORK_DIR/source.tar.gz"
SOURCE_DIR="$WORK_DIR/source"
mkdir "$SOURCE_DIR"

echo "Downloading $REPOSITORY at $REVISION"
curl --fail --location --retry 3 --connect-timeout 20 \
  "https://github.com/$REPOSITORY/archive/$REVISION.tar.gz" \
  --output "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$SOURCE_DIR" --strip-components=1

BUILD_TAG="$(date -u +%Y%m%d%H%M%S)"
IMAGE="sub2api-fork:$BUILD_TAG"
echo "Building $IMAGE"
docker build --quiet --pull --tag "$IMAGE" --tag sub2api-fork:main "$SOURCE_DIR"

if grep -q '^    image: weishaw/sub2api:latest$' "$COMPOSE_FILE"; then
  sed -i 's|^    image: weishaw/sub2api:latest$|    image: ${SUB2API_IMAGE:-sub2api-fork:main}|' "$COMPOSE_FILE"
elif ! grep -q '^    image: ${SUB2API_IMAGE:-sub2api-fork:main}$' "$COMPOSE_FILE"; then
  echo "The Sub2API image line in $COMPOSE_FILE is not recognized." >&2
  exit 1
fi

compose config --quiet
echo "Deploying $IMAGE while retaining existing mounts and database volumes"
DEPLOYMENT_STARTED=true
SUB2API_IMAGE="$IMAGE" compose up -d --no-deps --force-recreate sub2api

for attempt in $(seq 1 60); do
  NEW_CONTAINER="$(compose ps -q sub2api)"
  HEALTH="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$NEW_CONTAINER" 2>/dev/null || true)"
  if [[ "$HEALTH" == "healthy" ]]; then
    if curl --fail --silent --show-error --max-time 10 http://127.0.0.1:18080/api/v1/settings/public >/dev/null; then
      echo "Update complete. Backup: $BACKUP_DIR"
      exit 0
    fi
  fi
  if [[ "$HEALTH" == "unhealthy" ]]; then
    break
  fi
  sleep 2
done

echo "The new container did not become healthy." >&2
exit 1
