#!/bin/bash
OIDC_ENDPOINT=$(jq -r '.HttpConfig.OIDCConfigEndpoint' /etc/netbird/management.json)
KEY_CHECK_INTERVAL_SECONDS="${KEY_CHECK_INTERVAL_SECONDS:-3600}"
KEYS_FILE="/data/oidc_keys.json"

fetch_keys() {
  config=$(curl -s "$OIDC_ENDPOINT")
  jwks_uri=$(echo "$config" | jq -r '.jwks_uri')
  curl -s "$jwks_uri"
}

keys_changed() {
  local new_keys="$1"
  if [ ! -f "$KEYS_FILE" ]; then
    return 0
  fi
  local old_keys=$(cat "$KEYS_FILE")
  [ "$new_keys" != "$old_keys" ]
}

restart_pod() {
  echo "Restarting pod..."
  kill 1
}

while true; do
  echo "Fetching OIDC keys..."
  new_keys=$(fetch_keys)

  if keys_changed "$new_keys"; then
    echo "Keys have changed. Updating stored keys..."
    echo "$new_keys" > "$KEYS_FILE"
    restart_pod
  else
    echo "Keys have not changed. No action required."
  fi

  echo "Sleeping for $KEY_CHECK_INTERVAL_SECONDS seconds..."
  sleep "$KEY_CHECK_INTERVAL_SECONDS"
done
