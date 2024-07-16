#!/bin/bash
set +x
echo "Retrieving users and groups from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
GroupsList=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2 column3 column4 column5 column6 column7 column8
do
  column3=`echo "$column3" | tr '[:upper:]' '[:lower:]'`
  echo "E-mail: $column3"
  echo "CC SP Group: $column4"
  echo "Berechtigungsgruppen: $column6"
  IFS=,
  read line <<<$column6
  Berechtigungsgruppen=( $line )
  declare -p Berechtigungsgruppen
  GroupID=`echo "${GroupsList}" | jq -r '.[] | select(.name == "'"$column4"'") | .id' | tr -d '\r'`
  if [ -z "$GroupID" ]
  then
        echo "CC SP GroupID: Group not found!"
  else
        echo "CC SP GroupID: $GroupID"
  fi
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column3"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "Missing UserID!"
  else
        echo "UserID: $UserID"
        if [ ! -z "$GroupID" ]
        then
            gc groups members delete $GroupID --ids $UserID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
        fi
        for value in "${Berechtigungsgruppen[@]}"
        do
          echo "Berechtigungsgruppen: $value"
          GroupID=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment | jq -r '.[] | select(.name == "'"$value"'") | .id' | tr -d '\r'`
          if [ -z "$GroupID" ]
          then
                echo "BerechtigungsgruppenID: Group not found!"
          else
                echo "BerechtigungsgruppenID: $GroupID"
                gc groups members delete $GroupID --ids $UserID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
          fi
        done
        echo "User $column3 removed from $column4,$column6"
  fi
  echo
done <<< "$(tail -n +2 RemoveUsersGroups.csv)"
