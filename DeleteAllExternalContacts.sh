#!/bin/bash

echo -e "Creating list of IDs of all external contacts...\n"

gc externalcontacts contacts search -s --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment | jq -r '.entities[].id' | tr -d '\r' > ContactID_List
#read the array
mapfile -t contactID_array < <(cat ContactID_List)
#remove according to the ID list
for contact in "${contactID_array[@]}"; do 
    gc externalcontacts contacts delete $contact --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment; 
done
rm ContactID_List