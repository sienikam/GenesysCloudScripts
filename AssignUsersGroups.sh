#!/bin/bash
set +x
echo "Retrieving users and groups from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
GroupsList=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2 column3
do
  column1=`echo "$column1" | tr '[:upper:]' '[:lower:]'`
  echo "E-mail: $column1"
  echo "CC SP Group: $column2"
  echo "Berechtigungsgruppen: $column3"
  IFS=,
  read line <<<$column3
  Berechtigungsgruppen=( $line )
  declare -p Berechtigungsgruppen
  GroupID=`echo "${GroupsList}" | jq -r '.[] | select(.name == "'"$column2"'") | .id' | tr -d '\r'`
  if [ -z "$GroupID" ]
  then
        echo "CC SP GroupID: Group not found!"
  else
        echo "CC SP GroupID: $GroupID"
  fi
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column1"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "Missing UserID!"
  else
        echo "UserID: $UserID"
        if [ ! -z "$GroupID" ]
        then
        	echo '{"memberIds": ["'"$UserID"'"], "version": 0}' | tr -d '\r' | gc groups members add $GroupID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
        fi
        for value in "${Berechtigungsgruppen[@]}"
        do
          echo "Berechtigungsgruppen: $value"
          GroupID=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment | jq -r '.[] | select(.name | test("'"^$value$"'";"i")) | .id' | tr -d '\r'`
          if [ -z "$GroupID" ]
          then
                echo "BerechtigungsgruppenID: Group not found!"
          else
                echo "BerechtigungsgruppenID: $GroupID"
                echo '{"memberIds": ["'"$UserID"'"], "version": 0}' | tr -d '\r' | gc groups members add $GroupID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
          fi
        done
        echo "User $column1 added into $column2,$column3"
  fi
  echo
done <<< "$(tail -n +2 AssignUsersGroups.csv)"
