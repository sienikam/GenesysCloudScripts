#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2 column3 column4 column5 column6 column7 column8 column9
do
  echo "User: $column4"
  echo "ACDAutoAnswer: $column1"
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column4"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $column4 not found!"
  else
        echo "UserID: $UserID"
        Version=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column4"'") | .version' | tr -d '\r'`
        echo "Version: $Version"
        echo '{"acdAutoAnswer":"'"$column1"'","version":"'"$Version"'"}' | gc users update $UserID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
  fi
  echo
done <<< "$(tail -n +2 ACDAutoAnswer.csv)"
