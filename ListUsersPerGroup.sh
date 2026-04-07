#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
GroupsList=`gc groups list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
while IFS=";" read -r group
do
    echo "Group: $group"
    GroupID=`echo "${GroupsList}" | jq -r '.[] | select(.name | test("'"^$group$"'";"i")) | .id' | tr -d '\r'`
    UsersList=`gc groups members list --expand groups,skills $GroupID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
    # Iterate over each user in the UsersList
    echo "email,routingskills,queues,groups,divisions" > UsersPerGroup.csv
    echo "$UsersList" | jq -c '.entities[]' | while read -r user; do
    user_id=$(echo "$user" | jq -r '.id')
    user_email=$(echo "$user" | jq -r '.email')
    user_routingskills=$(echo "$user" | jq -r '.skills[] | "\(.name)=\(.proficiency)"' | paste -sd ";" -)
    user_queues=$(gc users queues list $user_id | jq -r '.entities[] | "\(.name)=\(.joined)"' | paste -sd ";" -)
    user_groups=$(echo "$user" | jq -r '.groups[] | .id' | while read -r group_id; do
        group_name=$(echo "${GroupsList}" | jq -r '.[] | select(.id=="'"$group_id"'") | .name')
        echo $group_name
    done | paste -sd ";" -)
    user_divisions=$(echo "$user" | jq -r '.division.name')
    echo "$user_email,$user_routingskills,$user_queues,$user_groups,$user_divisions" >> UsersPerGroup.csv
done
done <<< "$(tail -n +2 ListUsersPerGroup.csv)"