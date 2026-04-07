#!/bin/bash

# Define an associative array to map variable names to filenames
declare -A data_map=(
  [ArchitectIvrList]="ArchitectIvrList.txt"
  [DivisionList]="DivisionList.txt"
  [FlowsList]="FlowsList.txt"
  [GroupsList]="GroupsList.txt"
  [IntegrationsList]="IntegrationsList.txt"
  [QueuesList]="QueuesList.txt"
  [RolesList]="RolesList.txt"
  [ScriptList]="ScriptList.txt"
  [SkillsList]="SkillsList.txt"
  [StationsList]="StationsList.txt"
  [UsersList]="UsersList.txt"
  [WrapUpCodesList]="WrapUpCodesList.txt"
)

# Loop through the array to execute commands and save outputs
echo "Retrieving data from Genesys Cloud..."
echo
for var in "${!data_map[@]}"; do
  case $var in
    ArchitectIvrList)
      cmd="gc architect ivrs list -a --clientid \"$oauthclient_id\" --clientsecret \"$oauthclient_secret\" --environment \"$environment\""
      ;;
    DivisionList)
      cmd="gc authorization divisions list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    FlowsList)
      cmd="gc flows list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    GroupsList)
      cmd="gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    IntegrationsList)
      cmd="gc integrations list -a --clientid \"$oauthclient_id\" --clientsecret \"$oauthclient_secret\" --environment \"$environment\""
      ;;
    QueuesList)
      cmd="gc routing queues list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    RolesList)
      cmd="gc authorization roles list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    ScriptList)
      cmd="gc scripts list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    SkillsList)
      cmd="gc routing skills list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    StationsList)
      cmd="gc stations list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    UsersList)
      cmd="gc users list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
    WrapUpCodesList)
      cmd="gc routing wrapupcodes list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment"
      ;;
  esac
  
  echo "Running backup for $var..."
  output=$(eval $cmd)
  echo "$output" > "${data_map[$var]}"
  echo "$var data saved to ${data_map[$var]}"
done
