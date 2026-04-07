#!/bin/bash

set +x

# Check if the CSV with DID Numbers exist.
if [[ ! -f CreateSingleDIDRangesForPersonalHotlines.sh ]]; then
  echo -e "\nError: File CreateSingleDIDRangesForPersonalHotlines.sh not found. Exiting...\n"
  exit 1
fi

while IFS=";" read -r didnumber comment description
do

payload=$(cat <<EOF
{
    "comments": "$comment",
    "startPhoneNumber": "$didnumber'",
    "endPhoneNumber": "'$didnumber'",
    "description": "$description"
}
EOF
)

echo -e "\n\nCreating DID range for number "$didnumber"...\n\n"
echo "$payload" | gc telephony providers edges didpools create --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"; sleep 0.5

if [[ $? -eq 0 ]]; then
    echo -e "\n\nDID range for number "$didnumber" has been created...\n\n"
else
    echo -e "\n\nSomething went wrong while creating the DID range. Stopping here...Check logs...\n\n"
    exit 1
fi

done <<< "$(tail -n +2 CreateSingleDIDRangesForPersonalHotlines.csv)"