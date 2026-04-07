#!/bin/bash

# fix newline from API response
# column3=`echo "$column3" | tr -d '\r'`

set +x

echo "Retrieving data from Genesys Cloud.."
SkillList=`gc routing skills list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r skill
do
  skill_id=`echo "${SkillList}" | jq -r '.[] | select(.name == "'"$skill"'") | .id' | tr -d '\r'`
  echo "Skill: $skill"
  if [ -z "$skill_id" ]
  then
      echo -e "Skill $skill not found. \n"
  else
      echo "SkillID: $skill_id"
      gc routing skills delete $skill_id --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
      echo -e "Skill $skill deleted. \n"
  fi
done <<< "$(tail -n +2 DeleteSkills.csv)"
