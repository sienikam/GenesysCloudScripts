#!/bin/bash

# fix newline from API response
# column3=`echo "$column3" | tr -d '\r'`

set +x

echo "Retrieving data from Genesys Cloud.."
UserList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r user
do
  user_id=`echo "${UserList}" | jq -r '.[] | select(.email == "'"$user"'") | .id' | tr -d '\r'`
  echo "User: $user"
  if [ -z "$user_id" ]
  then
      echo -e "User $user not found. \n"
  else
      echo "UserID: $user_id"
      echo '{"name":"GDPR_DELETE","requestType": "GDPR_DELETE", "subject": {"userId": "'"$user_id"'"}}' | gc gdpr requests create --deleteConfirmed=true --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
      echo -e "User $user deleted. \n"
  fi
done <<< "$(tail -n +2 GDPR_DeleteUser.csv)"
