#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
QueuesList=`gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

#!/bin/bash
while IFS=";" read -r user queues
do
  user=`echo "$user" | tr '[:upper:]' '[:lower:]' | tr -d '\r'`
  queues=`echo "$queues" | tr -d '\r'`
  echo "User: $user"
  echo "Queues: $queues"
  IFS=,
  read line <<<$queues
  Queues=( $line )
  declare -p Queues
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email | test("'"^$user$"'";"i")) | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $user not found!"
  else
        echo "UserID: $UserID"
        for value in "${Queues[@]}"
        do
          echo "Queue: $value"
          QueueID=`echo "${QueuesList}" | jq -r '.[] | select(.name | test("'"^$value$"'";"i")) | .id' | tr -d '\r'`
          queues=`echo "$queues" | tr -d '\r'`
          if [ -z "$QueueID" ]
          then
                echo "Queue $value not found!"
          else
                echo "QueueID: $QueueID"
                echo '[{"id":"'"$UserID"'","joined":false}]' | gc routing queues members activate $QueueID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
          fi
         done
  fi
  echo
done <<< "$(tail -n +2 DeactivateUsersQueues.csv)"
