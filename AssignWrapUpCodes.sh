#!/bin/bash

set +x

echo "Retrieving data from Genesys Cloud.."
QueuesList=`gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
WrapUpCodesList=`gc routing wrapupcodes list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r queue wrapupcode1 wrapupcode2 wrapupcode3 wrapupcode4 wrapupcode5 wrapupcode6 wrapupcode7 wrapupcode8 wrapupcode9 wrapupcode10 wrapupcode11 wrapupcode12 wrapupcode13 wrapupcode14 wrapupcode15 wrapupcode16 wrapupcode17 wrapupcode18 wrapupcode19 wrapupcode20 wrapupcode21 wrapupcode22 wrapupcode23 wrapupcode24 wrapupcode25 wrapupcode26 wrapupcode28 wrapupcode29 wrapupcode30 wrapupcode31 wrapupcode32 wrapupcode33 wrapupcode34 wrapupcode35 wrapupcode36 wrapupcode37 wrapupcode38 wrapupcode39 wrapupcode40 wrapupcode41 wrapupcode42 wrapupcode43 wrapupcode44 wrapupcode45 wrapupcode46 wrapupcode47 wrapupcode48 wrapupcode49 wrapupcode50 
do
  queues_id=`echo "${QueuesList}" | jq -r '.[] | select(.name == "'"$queue"'") | .id' | tr -d '\r'`
  
  number_of_wrapupcodes=50  # Adjust the number of codes as needed

  for ((i=1; i<=$number_of_wrapupcodes; i++)); do
    wrapupcode_id_var="wrapupcode${i}_id"
    wrapupcode_var="wrapupcode${i}"

    if [ -n "${!wrapupcode_var}" ]; then
      # Fetch the id for the current wrapup code
      id=$(echo "${WrapUpCodesList}" | jq -r --arg code "${!wrapupcode_var}" '.[] | select(.name == $code) | .id' | tr -d '\r')

      # Assign the id to the dynamically generated variable
      declare "${wrapupcode_id_var}=${id}"
    fi
  done

  echo "Queue: $queue"
  echo "Queue ID: $queues_id"

  # Loop to generate and echo variables
  for ((i = 1; i <= number_of_wrapupcodes; i++)); do
    wrapupcode="wrapupcode${i}"
    wrapupcode_id="${wrapupcode}_id"
    
    if [ -n "${!wrapupcode}" ]; then
      echo "WrapUpCode: ${!wrapupcode}"
      echo "WrapUpCode ID: ${!wrapupcode_id}"
    fi
  done

  # Assuming $number_of_wrapupcodes is set appropriately

  wrapupcodes_json='['

  for ((i=1; i<=$number_of_wrapupcodes; i++)); do
    wrapupcode_id_var="wrapupcode${i}_id"
    wrapupcode_var="wrapupcode${i}"

    # Fetch the id for the current wrapup code
    id=$(echo "${WrapUpCodesList}" | jq -r --arg code "${!wrapupcode_var}" '.[] | select(.name == $code) | .id' | tr -d '\r')

    # Assign the id to the dynamically generated variable
    declare "${wrapupcode_id_var}=${id}"

    # Add the id to the JSON string
    wrapupcodes_json+='{"id": "'"$id"'"},'
  done

  # Remove the trailing comma and close the JSON array
  wrapupcodes_json=${wrapupcodes_json%,}
  wrapupcodes_json+=']'

  # Use the dynamic JSON string in your command
  echo "$wrapupcodes_json" | gc routing queues wrapupcodes create $queues_id --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment

done <<< "$(tail -n +2 AssignWrapUpCodes.csv)"
