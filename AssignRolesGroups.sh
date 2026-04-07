#!/bin/bash
set +x
echo "Retrieving roles, groups and divisions from Genesys Cloud.."
RolesList=`gc authorization roles list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
GroupsList=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
DivisionList=`gc authorization divisions list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`

while IFS=";" read -r column1 column2 column3
do
  echo "Group: $column1"
  echo "Role: $column2"
  echo "Division: $column3"
  IFS=,
  read line_roles <<<$column2
  Roles=( $line_roles )
  declare -p Roles
  read line_divisions <<<$column3
  Divisions=( $line_divisions )
  declare -p Divisions
  GroupID=`echo "${GroupsList}" | jq -r '.[] | select(.name | test("'"^$column1$"'";"i")) | .id' | tr -d '\r'`
  if [ -z "$GroupID" ]
  then
      echo "Group $column1 not found!"
  else
      echo
      for role in "${Roles[@]}"
      do
            RoleID=`echo "${RolesList}" | jq -r '.[] | select(.name | test("'"^$role$"'";"i")) | .id' | tr -d '\r'`
            if [ -z "$RoleID" ]
            then
                  echo "Role $role not found!"
            else
                  for division in "${Divisions[@]}"
                  do
                        DivisionID=`echo "${DivisionList}" | jq -r '.[] | select(.name | test("'"^$division$"'";"i")) | .id' | tr -d '\r'`
                        if [ -z "$DivisionID" ]
                        then
                              echo "Division $division not found!"
                        else
                              echo "Group: $column1 ($GroupID), Role: $role ($RoleID), Division: $division ($DivisionID)"
                              echo '{"subjectIds":["'"$GroupID"'"],"divisionIds":["'"$DivisionID"'"]}' | gc authorization roles bulkgrant --subjectType PC_GROUP $RoleID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
                        fi
                  done
            fi
        done
  fi
  echo
done <<< "$(tail -n +2 AssignRolesGroups.csv)"
