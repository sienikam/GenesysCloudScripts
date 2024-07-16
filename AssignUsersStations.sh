#!/bin/bash
set +x

echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
StationsList=`gc stations list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2
do
  column1=`echo "$column1" | tr -d '\r'`
  column2=`echo "$column2" | tr -d '\r'`
  echo "User: $column1"
  echo "Station: $column2"
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column1"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
      echo "User $column1 not found!"
  else
      StationID=`echo "${StationsList}" | jq -r '.[] | select(.name == "'"$column2"'") | .id' | tr -d '\r'`
      if [ -z "$StationID" ]
      then
            echo "Station $column2 not found!"
      else
            gc users station defaultstation update $UserID $StationID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
      fi
  fi
  echo
done <<< "$(tail -n +2 AssignUsersStations.csv)"
