#!/bin/bash
#source build-esen.sh

# check if bearychat webhook url is present
if [ -z "$WERCKER_BEARYCHAT_NOTIFIER_URL" ]; then
  fail "Please provide a BearyChat webhook URL"
fi

# check if a '#' was supplied in the channel name
if [ "${WERCKER_BEARYCHAT_NOTIFIER_CHANNEL:0:1}" = '#' ]; then
  export WERCKER_BEARYCHAT_NOTIFIER_CHANNEL=${WERCKER_BEARYCHAT_NOTIFIER_CHANNEL:1}
fi

# check if this event is a build or deploy
if [ -n "$DEPLOY" ]; then
  # its a deploy!
  export ACTION="Deploy"
  export ACTION_URL=$WERCKER_DEPLOY_URL
else
  # its a build!
  export ACTION="Build"
  export ACTION_URL=$WERCKER_BUILD_URL
fi

export REPO_NAME="$WERCKER_GIT_DOMAIN/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
export BC_TEXT="[$REPO_NAME](https://$REPO_NAME)"
export TITLE="$ACTION passed"
export MESSAGE="[$ACTION]($ACTION_URL) for \`$WERCKER_APPLICATION_NAME\` by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch \`$WERCKER_GIT_BRANCH\`"
export COLOR="green"

if [ "$WERCKER_RESULT" = "failed" ]; then
  export TITLE="$ACTION failed"
  export MESSAGE="$MESSAGE at step: \`$WERCKER_FAILED_STEP_DISPLAY_NAME\`"
  export COLOR="red"
fi

# construct the json
json="{"

# channels are optional, dont send one if it wasnt specified
if [ -n "$WERCKER_BEARYCHAT_NOTIFIER_CHANNEL" ]; then 
    json=$json"\"channel\": \"#$WERCKER_BEARYCHAT_NOTIFIER_CHANNEL\","
fi

json=$json"
    \"text\": \"$BC_TEXT\",
    \"attachments\":[
      {
        \"title\": \"$TITLE\",
        \"text\": \"$MESSAGE\",
        \"color\": \"$COLOR\"
      }
    ]
}"

# skip notifications if not interested in passed builds or deploys
if [ "$WERCKER_BEARYCHAT_NOTIFIER_NOTIFY_ON" = "failed" ]; then
	if [ "$WERCKER_RESULT" = "passed" ]; then
		return 0
	fi
fi

# skip notifications if not on the right branch
if [ -n "$WERCKER_BEARYCHAT_NOTIFIER_BRANCH" ]; then
    if [ "$WERCKER_BEARYCHAT_NOTIFIER_BRANCH" != "$WERCKER_GIT_BRANCH" ]; then
        return 0
    fi
fi

# post the result to the webhook
echo curl -d "payload=$json" -s "$WERCKER_BEARYCHAT_NOTIFIER_URL" --output "$WERCKER_STEP_TEMP"/result.txt -w "%{http_code}"
RESULT=$(curl -d "payload=$json" -s "$WERCKER_BEARYCHAT_NOTIFIER_URL" --output "$WERCKER_STEP_TEMP"/result.txt -w "%{http_code}")
cat "$WERCKER_STEP_TEMP/result.txt"

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No token is specified."
  fi

  if grep -Fqx "No hooks" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No text specified."
  fi
fi

if [ "$RESULT" = "404" ]; then
  fail "Subdomain or token not found."
fi
