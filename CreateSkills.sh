#!/bin/bash

set +x

while IFS=";" read -r column1
do
  echo "ACD Skill: $column1"
  echo '{"name": "'"$column1"'"}' | tr -d '\r' | gc routing skills create --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
  echo "ACD Skill: $column1 created.." | tr -d '\r'
done <<< "$(tail -n +2 CreateSkills.csv)"
