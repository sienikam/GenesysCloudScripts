#!/bin/bash

set +x

# Check if CreateDivisions.csv exists
if [[ ! -f CreateDivisions.csv ]]; then
  echo "Error: CreateDivisions.csv not found. Exiting..."
  exit 1
fi

echo -e "Creating divisions according to the CSV...\n"

while IFS=";" read -r division description
do

payload=$(cat <<EOF
{
  "name": "$division",
  "description": "$description"
}
EOF
)

echo "$payload" | gc authorization divisions create -i --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

if [[ $? -eq 0 ]]; then
    echo -e "\n\nDivision "$division" has been created...\n\n"
else
    echo -e "\n\nSomething went wrong. Stopping here...Check pipeline logs...\n\n"
    exit 1
fi

done <<< "$(tail -n +2 CreateDivisions.csv)"