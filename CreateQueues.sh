#!/bin/bash

# fix newline from API response
# column3=`echo "$column3" | tr -d '\r'`

set +x

echo "Retrieving data from Genesys Cloud.."
DivisionList=`gc authorization divisions list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
FlowsList=`gc flows list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
ScriptList=`gc scripts list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r name division description alertingtimeoutseconds servicelevel_percentage servicelevel_durationms acwsettings_wrapuprompt acwsettings_timeoutms skillevaluationmethod callingpartynumber callingpartyname queueflow defaultscripts
do
  division_id=`echo "${DivisionList}" | jq -r '.[] | select(.name == "'"$division"'") | .id' | tr -d '\r'`
  queueflow_id=`echo "${FlowsList}" | jq -r '.[] | select(.name == "'"$queueflow"'") | .id' | tr -d '\r'`
  defaultscripts_id=`echo "${ScriptList}" | jq -r '.[] | select(.name == "'"$defaultscripts"'") | .id' | tr -d '\r'`
  echo "Queue: $name"
  echo "Division: $division"
  echo "Description: $description"
  echo "Alerting Timeout (Seconds): $alertingtimeoutseconds"
  echo "Service Level: $servicelevel_percentage"
  echo "Service Level Target (Miliseconds): $servicelevel_durationms"
  echo "After Call Work: $acwsettings_wrapuprompt"
  echo "After Call Work Timeout (Miliseconds): $acwsettings_timeoutms"
  echo "Evaluation Method: $skillevaluationmethod"
  echo "Calling Party Number: $callingpartynumber"
  echo "Calling Party Name: $callingpartyname"
  echo "In-queue Flow: $queueflow"
  echo "Default Script: $defaultscripts"
  echo '{"name":"'"$name"'","division":{"id":"'"$division_id"'"},"description": "'"$description"'", "mediaSettings":{"call":{"alertingTimeoutSeconds":"'"$alertingtimeoutseconds"'","serviceLevel":{"percentage":"'"$servicelevel_percentage"'","durationMs":"'"$servicelevel_durationms"'"}}},"acwSettings":{"wrapupPrompt":"'"$acwsettings_wrapuprompt"'","timeoutMs":"'"$acwsettings_timeoutms"'"},"skillEvaluationMethod":"'"$skillevaluationmethod"'", "callingPartyNumber": "'"$callingpartynumber"'", "callingPartyName": "'"$callingpartyname"'", "queueFlow":{"id":"'"$queueflow_id"'"}, "defaultScripts":{"CALL":{"id":"'"$defaultscripts_id"'"}}}'  | gc routing queues create --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
done <<< "$(tail -n +2 CreateQueues.csv)"
