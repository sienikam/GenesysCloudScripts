#!/bin/bash

set +x

# Check if the CSV with WebRTCs names exist
if [[ ! -f ChangeWebRTCNames.csv ]]; then
  echo -e "\nError: File ChangeWebRTCNames.csv not found. Exiting...\n"
  exit 1
fi

while IFS=";" read -r existingname newname
do

echo -e "\nNeed to obtain the ID of "$existingname" WebRTC from the CSV...\n"
phone_id=$(gc telephony providers edges phones list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" | jq -r '.[] | select(.name == "'"$existingname"'") | .id' | tr -d '\r')

echo -e "\nNeed to obtain the JSON file for the "$existingname" WebRTC in order to alter it.."
gc telephony providers edges phones get "$phone_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"  > phone."$phone_id".json

echo -e "\nChanging the name of the WebRTC "$existingname" to "$newname"...\n"
sed -i 's/"'$existingname'"/"'$newname'"/g' phone."$phone_id".json

gc telephony providers edges phones update "$phone_id" -f phone."$phone_id".json --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

if [[ $? -eq 0 ]]; then
    echo -e "\n\n\nThe WebRTC "$existingname" was renamed to "$newname"...\n\n\n"
else
    echo -e "\n\nSomething went wrong. Stopping here...Check logs...\n\n"
    exit 1
    rm phone.*.json
fi

rm phone."$phone_id".json

done <<< "$(tail -n +2 ChangeWebRTCNames.csv)"