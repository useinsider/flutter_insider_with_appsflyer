#!/usr/bin/env bash
SLACK_ENDPOINT="https://mobile.useinsider.com/api/lilith/slack_notifier"

CHANNEL=$1
USERNAME=$2
TEXT="$3"

generate_post_data()
{
  cat <<EOF
{
  "auth_key": "$SLACK_NOTIFIER_AUTH_KEY",
  "channel": "$CHANNEL",
  "message": "$TEXT",
  "username": "$USERNAME"
}
EOF
}

curl -i -H "Content-Type:application/json" -X POST --data "$(generate_post_data)" $SLACK_ENDPOINT >/dev/null 2>&1