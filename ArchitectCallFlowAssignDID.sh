#!/bin/bash
set +x
echo "Retrieving architect call flows from Genesys Cloud..."

# Retrieve integrations and groups
ArchitectIvrList=$(gc architect ivrs list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment")

while IFS=";" read -r ArchitectCallFlow DID_Numbers
do
  echo "Architect Call Flow: $ArchitectCallFlow"
  echo "DID_Numbers: $DID_Numbers"

  # Read the DID_Numbers into an array
  IFS=',' read -ra DID_Numbers <<< "$DID_Numbers"

  #ArchitectCallFlowID=$(echo "${ArchitectIvrList}" | jq -r '.[] | select(.name | test("'"^$ArchitectCallFlow$"'";"i")) | .id' | tr -d '\r\n')
  ArchitectCallFlowID=$(echo "${ArchitectIvrList}" | jq -r --arg name "$ArchitectCallFlow" '.[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .id' | tr -d '\r\n')
  if [ -z "$ArchitectCallFlowID" ]
  then
      echo "Architect Call Flow: $ArchitectCallFlow not found!"
  else
      ArchitectCallFlowCurrentConfig=$(gc architect ivrs get "$ArchitectCallFlowID" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment")
      #echo $ArchitectCallFlowCurrentConfig | jq .
      # Build JSON array of DID Numbers
      DID_Numbers_JSON=$(printf '%s\n' "${DID_Numbers[@]}" | jq -R . | jq -s .)
      
      # Update the integration config JSON with the new group IDs and increment version
      NewConfig=$(echo "$ArchitectCallFlowCurrentConfig" | jq --argjson dnis "$DID_Numbers_JSON" '.dnis += $dnis')
      echo "$NewConfig" | gc architect ivrs update "$ArchitectCallFlowID" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
      sleep 5
   fi
done <<< "$(tail -n +2 ArchitectCallFlowAssignDID.csv)"
