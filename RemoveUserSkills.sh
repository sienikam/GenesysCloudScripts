#!/bin/bash
set +x
echo "Retrieving users and skills from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
SkillsList=`gc routing skills list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2
do
  column3=`echo "$column1" | tr '[:upper:]' '[:lower:]'`
  echo "E-mail: $column1"
  IFS=,
  read line <<<$column2
  Skills=( $line )
  declare -p Skills
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$column1"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "Missing UserID!"
  else
    for value in "${Skills[@]}" 
    do
        echo "Skill: $value"
        SkillID=`echo "${SkillsList}" | jq -r '.[] | select(.name == "'"$value"'") | .id' | tr -d '\r'`
        if [ -z "$SkillID" ]
        then
            echo "SkillID: Skill not found!"
        else
            echo "SkillID: $SkillID"
            gc users routingskills delete $UserID $SkillID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
        fi
        done
        echo "User $column1 removed skills $column2"
  fi
  echo
done <<< "$(tail -n +2 RemoveUserSkills.csv)"