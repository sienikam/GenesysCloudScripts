#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
UsersList=`gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
SkillsList=`gc routing skills list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r user skill_string
do
  username=`echo "$user" | tr '[:upper:]' '[:lower:]' | tr -d '\r'`
  echo "User: $user"
  
  # Split the skill string into an array
  IFS=',' read -ra SKILL_ARRAY <<< "$skill_string"
  
  UserID=`echo "${UsersList}" | jq -r '.[] | select(.email == "'"$username"'") | .id' | tr -d '\r'`
  if [ -z "$UserID" ]
  then
        echo "User $user not found!"
  else
      echo "UserID: $UserID"
      
      # Iterate through skills
      for skill_prof in "${SKILL_ARRAY[@]}"
      do
            # Split skill and proficiency
            IFS=':' read -r skill_name proficiency <<< "$skill_prof"
            
            # Trim whitespace
            skill_name=$(echo "$skill_name" | xargs)
            proficiency=$(echo "$proficiency" | xargs)
            
            echo "Processing Skill: $skill_name (Proficiency: $proficiency)"
            
            # Find Skill ID
            SkillID=`echo "${SkillsList}" | jq -r '.[] | select(.name | test("'"^$skill_name$"'";"i")) | .id' | tr -d '\r'`
            
            if [ -z "$SkillID" ]
            then
                  echo "Skill $skill_name not found!"
            else
                  echo "SkillID: $SkillID"
                  echo '{"id":"'"$SkillID"'","proficiency":"'"$proficiency"'"}' | gc users routingskills create $UserID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
                  echo "User $user added skill $skill_name with proficiency $proficiency"
            fi
      done
  fi
  echo
done <<< "$(tail -n +2 AssignUsersSkills.csv)"