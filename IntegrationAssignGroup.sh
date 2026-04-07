#!/bin/bash
set +x
echo "Retrieving integrations and groups from Genesys Cloud..."

# Retrieve integrations and groups
IntegrationsList=$(gc integrations list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment")
GroupsList=$(gc groups list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment")

while IFS=";" read -r Integration Groups
do
  echo "Integration: $Integration"
  echo "Groups: $Groups"

  # Read the groups into an array
  IFS=',' read -ra Group <<< "$Groups"

  IntegrationID=$(echo "${IntegrationsList}" | jq -r '.[] | select(.name | test("'"^$Integration$"'";"i")) | .id' | tr -d '\r\n')
  if [ -z "$IntegrationID" ]
  then
      echo "Integration $Integration not found!"
  else
      echo
      IntegrationCurrentConfig=$(gc integrations config current get "$IntegrationID" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment")
      #echo "$IntegrationCurrentConfig"

      # Initialize an empty array to hold the GroupIDs
      GroupIDArray=()
      for group in "${Group[@]}"
      do
        GroupID=$(echo "${GroupsList}" | jq -r '.[] | select(.name | test("'"^$group$"'";"i")) | .id')
        if [ -z "$GroupID" ]
        then
            echo "Group $group not found!"
            else
                echo "Integration: $Integration ($IntegrationID), Group: $group ($GroupID)"
                # Add the GroupID to the array
                GroupIDArray+=("$GroupID")
            fi
        done

        # Build JSON array of group IDs
        GroupIDsJson=$(printf '%s\n' "${GroupIDArray[@]}" | jq -R . | jq -s .)

        # Update the integration config JSON with the new group IDs and increment version
        NewConfig=$(echo "$IntegrationCurrentConfig" | jq --argjson groupIds "$GroupIDsJson" '.properties.groups = $groupIds')

        echo "$NewConfig" | gc integrations config current update "$IntegrationID" --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
  fi
  echo
done <<< "$(tail -n +2 IntegrationAssignGroups.csv)"
