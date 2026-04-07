#!/bin/bash

set +x

echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r name description type rulesVisible visibility rolesEnabled owners
do
  echo
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$owners"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
      echo -e "User $owners not found. \n"
  else
      echo "Name: $name"
      echo "Description: $description"
      echo "Type: $type"
      echo "rulesVisible: $rulesVisible"
      echo "Visibility: $visibility"
      echo "RolesEnabled: $rolesEnabled"
      echo "Owners: $owners"
      echo '{"name": "'"$name"'","description": "'"$description"'","type":"'"$type"'","rulesVisible": "'"$rulesVisible"'","visibility":"'"$visibility"'","rolesEnabled":"'"$rolesEnabled"'","ownerIds": ["'"$UserID"'"]}' | gc groups create --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
  fi
done <<< "$(tail -n +2 CreateGroups.csv)"