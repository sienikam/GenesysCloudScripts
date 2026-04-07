#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
QueuesList=`gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

#!/bin/bash
while IFS=";" read -r column1 column2
do
  column1=`echo "$column1" | tr '[:upper:]' '[:lower:]' | tr -d '\r'`
  column2=`echo "$column2" | tr -d '\r'`
  echo "User: $column1"
  echo "Queues: $column2"
  IFS=,
  read line <<<$column2
  Queues=( $line )
  declare -p Queues
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column1"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $column1 not found!"
  else
        echo "UserID: $UserID"
        for value in "${Queues[@]}"
        do
          echo "Queue: $value"
          QueueID=`echo "${QueuesList}" | jq -r '.[] | select(.name | test("'"^$value$"'";"i")) | .id' | tr -d '\r'`
          column2=`echo "$column2" | tr -d '\r'`
          if [ -z "$QueueID" ]
          then
                echo "Queue $value not found!"
          else
                echo "QueueID: $QueueID"
                echo '[{"id":"'"$UserID"'"}]' | gc routing queues members move $QueueID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
          fi
         done
  fi
  echo
done <<< "$(tail -n +2 AssignUsersQueues.csv)"
