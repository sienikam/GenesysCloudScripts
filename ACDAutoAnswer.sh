#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2
do
  user=`echo "$column2" | tr '[:upper:]' '[:lower:]' | tr -d '\r'`
  echo "User: $user"
  echo "ACDAutoAnswer: $column1"
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$user"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $user not found!"
  else
        echo "UserID: $UserID"
        Version=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$user"'") | .version' | tr -d '\r'`
        echo "Version: $Version"
        echo '{"acdAutoAnswer":"'"$column1"'","version":"'"$Version"'"}' | gc users update $UserID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
  fi
  echo
done <<< "$(tail -n +2 ACDAutoAnswer.csv)"
