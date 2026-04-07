#!/bin/bash

set +x

# Check if DeleteRecordings.csv exists
if [[ ! -f DeleteRecordings.csv ]]; then
  echo "Error: DeleteRecordings.csv not found. Exiting..."
  exit 1
fi

while IFS=";" read -r interval actiondate
do
  echo "Interval: $interval"
  echo "Actiondate: $actiondate"

payload=$(cat <<EOF
{
  "action": "DELETE",
  "actionDate": "$actiondate",
  "screenRecordingActionDate": "$actiondate",
  "includeRecordingsWithSensitiveData": false,
  "includeScreenRecordings": true,
  "conversationQuery": {
    "interval": "$interval",
    "startOfDayIntervalMatching": true
  }
}
EOF
  )
  echo "$payload" | gc recording jobs create --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" > recjob.json
  echo -e "\nNeed to obtain the id of the created recording job now...\n"

  recjob_id=$(jq -r '.id' recjob.json | tr -d '\r')

  while true; do
    echo -e "Checking the job state if READY...\n"
    recjob_state=$(gc recording jobs get "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" | jq -r '.state' | tr -d '\r')

    if [[ "$recjob_state" == "READY" ]]; then
      echo -e "State is READY\n"
      break
    elif [[ "$recjob_state" == "PENDING" ]]; then
      echo -e "State is PENDING. This means, the number of recordings to delete is being calculated. Checking again in 20 seconds...\n"
      sleep 20
    else
      echo -e "Unwanted recording job state...Check the below printout:\n\n"
      gc recording jobs get "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
      exit 1
    fi
  done
  
  echo -e "Will now force the job start...\n"
  echo '{ "state": "PROCESSING" }' | gc recording jobs update "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

  while true; do
    echo -e "Checking the job state if FULFILLED...\n"
    recjob_state=$(gc recording jobs get "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" | jq -r '.state' | tr -d '\r')

    if [[ "$recjob_state" == "FULFILLED" ]]; then
      echo -e "State is FULFILLED. Finishing. The recordings have been marked for deletion. It can take a while until they disappear from the UI.\n\n"
      echo -e "Please review the job result:\n\n"
      gc recording jobs get "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
      rm recjob.json
      break
    elif [[ "$recjob_state" == "PROCESSING" ]]; then
      echo -e "State is PROCESSING. Checking again in 20 seconds...\n"
      sleep 20
    else
      echo -e "Unwanted recording job state...Check the below printout:\n\n"
      gc recording jobs get "$recjob_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
      rm recjob.json
      exit 1
    fi
  done
done <<< "$(tail -n +2 DeleteRecordings.csv)"