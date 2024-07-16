#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
QueuesList=`gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

#!/bin/bash
while IFS=";" read -r column1 column2 column3 column4 column5 column6 column7 column8 column9
do
  column4=`echo "$column4" | tr -d '\r'`
  column9=`echo "$column9" | tr -d '\r'`
  echo "User: $column4"
  echo "Queues: $column9"
  IFS=,
  read line <<<$column9
  Queues=( $line )
  declare -p Queues
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column4"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $column4 not found!"
  else
        echo "UserID: $UserID"
        for value in "${Queues[@]}"
        do
          echo "Queue: $value"
          QueueID=`echo "${QueuesList}" | jq -r '.[] | select(.name == "'"$value"'") | .id' | tr -d '\r'`
          column4=`echo "$column4" | tr -d '\r'`
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
