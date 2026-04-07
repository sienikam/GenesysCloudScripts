#!/bin/bash

set +x

if [[ ! -f AssignUserPhoneNumbers.csv ]]; then
  echo -e "\nError: File AssignUserPhoneNumbers.csv not found. Exiting...\n"
  exit 1
fi

echo -e "\nCreating an export of Users ...\n\n"
gc users list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"  > UsersList.json

while IFS=";" read -r useremail primary work1 work2 work3 mobile
do

user_id=$(cat UsersList.json | jq -r '.[] | select(.email == "'"$useremail"'") | .id' | tr -d '\r')
version=$(gc users get "$user_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"  | jq '.version')

  json_schema='{
    "version": "'$version'",'

  if [[ -n "$primary" ]]; then
    json_schema+='
      "primaryContactInfo": [
      {
        "address": "'$primary'",
        "display": "'$primary'",
        "mediaType": "PHONE",
        "type": "PRIMARY"
      }
    ],'
  fi

    json_schema+='"addresses": ['

  if [[ -n "$mobile" ]]; then
    json_schema+='
      {
        "address": "'$mobile'",
        "display": "'$mobile'",
        "mediaType": "SMS",
        "type": "MOBILE",
        "countryCode": "DE"
      },'
  fi
  
  if [[ -n "$work1" ]]; then
    json_schema+='
      {
        "address": "'$work1'",
        "display": "'$work1'",
        "mediaType": "PHONE",
        "type": "WORK",
        "countryCode": "DE"
      },'
  fi

  if [[ -n "$work2" ]]; then
    json_schema+='
      {
        "address": "'$work2'",
        "display": "'$work2'",
        "mediaType": "PHONE",
        "type": "WORK2",
        "countryCode": "DE"
      },'
  fi

  if [[ -n "$work3" ]]; then
    json_schema+='
      {
        "address": "'$work3'",
        "display": "'$work3'",
        "mediaType": "PHONE",
        "type": "WORK3",
        "countryCode": "DE"
      },'
  fi

json_schema+=']}'

payload="${json_schema::len-3}]}"

echo -e "\nAssigning contact numbers for user "$useremail"...\n\n"
echo "$payload" | gc users update "$user_id" -i --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

if [[ $? -eq 0 ]]; then
    echo -e "\n\nContact numbers for user "$useremail" have been assigned...\n\n"
else
    echo -e "\n\nSomething went wrong. Stopping here...Check pipeline logs...\n\n"
    rm UsersList.json
    exit 1
fi

done <<< "$(tail -n +2 AssignUserPhoneNumbers.csv)"
rm UsersList.json