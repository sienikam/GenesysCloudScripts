#!/bin/bash

# fix newline from API response
# column3=`echo "$column3" | tr -d '\r'`

set +x

echo "Retrieving data from Genesys Cloud.."
QueuesList=`gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r queue
do
  queue_id=`echo "${QueuesList}" | jq -r '.[] | select(.name == "'"$queue"'") | .id' | tr -d '\r'`
  echo "Queue: $queue"
  if [ -z "$queue_id" ]
  then
      echo -e "Queue $queue not found. \n"
  else
      echo "QueueID: $queue_id"
      gc routing queues delete $queue_id --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
      echo -e "Queue $queue deleted. \n"
  fi
done <<< "$(tail -n +2 DeleteQueues.csv)"
