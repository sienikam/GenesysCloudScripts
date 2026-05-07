#!/bin/bash
set +x

echo "Retrieving data from Genesys Cloud.."

gc users list -a \
  --expand "skills,languages,groups,locations,employerInfo,dateLastLogin" \
  --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
  > UsersList.json

gc groups list -a \
  --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
  > GroupsList.json

gc locations list -a \
  --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
  > LocationsList.json

gc routing queues list -a \
  --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
  > QueuesList.json

gc authorization roles list -a \
  --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
  > RolesList.json

# manager.id may reference an inactive user — build the lookup from the unfiltered list
ManagerMap=$(jq '[.[] | {key: .id, value: .email}] | from_entries' UsersList.json)

echo "Building queue membership map.."
: > /tmp/queue_members.jsonl
jq -r '.[] | "\(.id)\t\(.name)"' QueuesList.json | while IFS=$'\t' read -r qid qname; do
  gc routing queues members list -a "$qid" \
    --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
    | jq -c --arg qn "$qname" '.[]? | select(.joined==true) | {userId: .id, q: $qn}' \
    >> /tmp/queue_members.jsonl
done
QueueMap=$(jq -cs '
  group_by(.userId)
  | map({key: .[0].userId, value: ([.[].q] | join(","))})
  | from_entries
' /tmp/queue_members.jsonl)

echo "Building role-grants map.."
: > /tmp/role_grants.jsonl
jq -r '.[] | "\(.id)\t\(.name)"' RolesList.json | while IFS=$'\t' read -r rid rname; do
  gc authorization roles subjectgrants list -a "$rid" \
    --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" \
    | jq -c --arg rn "$rname" '.[]? | select(.type=="PC_USER") | {userId: .id, role: $rn, divs: [.divisions[]?.name | select(. != null and . != "")]}' \
    >> /tmp/role_grants.jsonl
done
RoleMap=$(jq -cs '
  group_by(.userId)
  | map({
      key: .[0].userId,
      value: (
        [.[]]
        | group_by(.divs)
        | map(
            if (.[0].divs | length) == 0 then
              ([.[].role] | join(", "))
            else
              ([.[].role] | join(", ")) + ": [" + (.[0].divs | join("; ")) + "]"
            end
          )
        | join(", ")
      )
    })
  | from_entries
' /tmp/role_grants.jsonl)

csv_escape() {
  local val="${1//$'\r'/}"
  if [[ "$val" == *,* || "$val" == *\"* || "$val" == *$'\n'* ]]; then
    val="${val//\"/\"\"}"
    printf '"%s"' "$val"
  else
    printf '%s' "$val"
  fi
}

echo 'name,email,phone_work,extension,title,department,email_manager,location_work,roles_divisions,queues,division,skills,hire_date' > UsersExport.csv

echo "Writing CSV.."
jq -c '.[] | select(.state == "active")' UsersList.json | while read -r user; do
  user_id=$(echo "$user" | jq -r '.id')
  user_email=$(echo "$user" | jq -r '.email // ""')
  echo "Processing: $user_email"

  user_name=$(echo "$user" | jq -r '.name // ""')
  user_phone=$(echo "$user" | jq -r '[.addresses[]? | select(.mediaType=="PHONE" and .type=="WORK") | .address // empty] | .[0] // ""')
  user_extension=$(echo "$user" | jq -r '[.addresses[]? | select(.mediaType=="PHONE" and .type=="WORK") | .extension // empty] | .[0] // ""')
  user_title=$(echo "$user" | jq -r '.title // ""')
  user_department=$(echo "$user" | jq -r '.department // ""')

  manager_id=$(echo "$user" | jq -r '.manager.id // empty')
  if [[ -n "$manager_id" ]]; then
    user_manager_email=$(echo "$ManagerMap" | jq -r --arg mid "$manager_id" '.[$mid] // ""')
  else
    user_manager_email=""
  fi

  location_id=$(echo "$user" | jq -r '.locations[0].locationDefinition.id // empty')
  if [[ -n "$location_id" ]]; then
    user_location=$(jq -r --arg lid "$location_id" '.[]? | select(.id==$lid) | .name' LocationsList.json)
  else
    user_location=""
  fi

  user_roles_divisions=$(echo "$RoleMap" | jq -r --arg uid "$user_id" '.[$uid] // ""')
  user_queues=$(echo "$QueueMap" | jq -r --arg uid "$user_id" '.[$uid] // ""')
  user_division=$(echo "$user" | jq -r '.division.name // ""')
  user_skills=$(echo "$user" | jq -r '[.skills[]? | "\(.name):\(.proficiency)"] | join(",")')
  user_hire_date=$(echo "$user" | jq -r '.employerInfo.dateHire // ""')

  {
    csv_escape "$user_name";             printf ','
    csv_escape "$user_email";            printf ','
    csv_escape "$user_phone";            printf ','
    csv_escape "$user_extension";        printf ','
    csv_escape "$user_title";            printf ','
    csv_escape "$user_department";       printf ','
    csv_escape "$user_manager_email";    printf ','
    csv_escape "$user_location";         printf ','
    csv_escape "$user_roles_divisions";  printf ','
    csv_escape "$user_queues";           printf ','
    csv_escape "$user_division";         printf ','
    csv_escape "$user_skills";           printf ','
    csv_escape "$user_hire_date";        printf '\n'
  } >> UsersExport.csv
done

echo "Export complete: $(($(wc -l < UsersExport.csv) - 1)) active users written to UsersExport.csv"

rm -f UsersList.json GroupsList.json LocationsList.json QueuesList.json RolesList.json
rm -f /tmp/queue_members.jsonl /tmp/role_grants.jsonl
