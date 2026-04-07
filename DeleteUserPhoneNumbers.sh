#!/bin/bash

set +x

# Check if the CSV with user email addresses exist for which we will be deleting the phone contact info.
if [[ ! -f DeleteUserPhoneNumbers.csv ]]; then
  echo -e "\nError: File DeleteUserPhoneNumbers.csv not found. Exiting...\n"
  exit 1
fi

echo -e "\nCreating an export of Users ...\n\n"
gc users list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"  > UsersList.json

while IFS=";" read -r useremail
do

user_id=$(cat UsersList.json | jq -r '.[] | select(.email == "'"$useremail"'") | .id' | tr -d '\r')
version=$(gc users get "$user_id" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"  | jq '.version')

payload=$(cat <<EOF
{
  "version": "$version",
  "addresses": [
  ]
}
EOF
)

echo -e "\n\n\nRemoving phone numbers for user "$useremail"...\n\n\n"
echo "$payload" | gc users update "$user_id" -i --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

if [[ $? -eq 0 ]]; then
    echo -e "\n\n\nPhone numbers for user "$useremail" has been removed...\n\n\n"
    sleep 0.5
else
    echo -e "\n\nSomething went wrong. Stopping here...Check pipeline logs...\n\n"
    rm UsersList.json
    exit 1
fi

done <<< "$(tail -n +2 DeleteUserPhoneNumbers.csv)"
rm UsersList.json