#!/bin/bash

set +x

# Check if CreateCannedResponses.csv exists
if [[ ! -f CreateCannedResponses.csv ]]; then
  echo "Error: CreateCannedResponses.csv not found. Exiting..."
  exit 1
fi

# Function to convert improper HTML to proper HTML in case it's necessary 
convert_html() {
    local input_text="$1"
    #Handle HREFS and format them to <a href=
    output_text=$(echo "$input_text" | sed -E 's/\[A HREF="([^"]+)"\]/<a href="\1">/Ig' | \
                             sed -E 's/\[A HREF=([^ ]+)\]/<a href="\1">/Ig' | \
                             sed -E 's/\[ *A +HREF *= *"([^"]+)" *(TARGET *= *"_blank")? *\]/<a href="\1" \2>/Ig;' | \
                             sed -E 's/\[\/A\]/<\/a>/Ig')
    # Convert [u] to <u> and [/u] to </u> for underlined text
    output_text=$(echo "$output_text" | sed -E 's/\[u\]/<u>/Ig' | sed -E 's/\[\/u\]/<\/u>/Ig')
    # Convert [b] to <b> and [/b] to </b> for bold text
    output_text=$(echo "$output_text" | sed -E 's/\[b\]/<b>/Ig' | sed -E 's/\[\/b\]/<\/b>/Ig')
    #Format as valid JSON
    content=$(echo "$output_text" | sed 's/"/\\"/g')
}

check_and_create_library() {

     library_id=$(gc responsemanagement libraries list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" | jq -r '.[] | select(.name == "'"$library"'") | .id' | tr -d '\r')

     if [[ -z $library_id ]]; then
        echo -e "\n\nThe library $library doesn't exist. Need to create it...\n\n"
        echo '{"name": "'"$library"'"}' | gc responsemanagement libraries create -i --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"
        library_id=$(gc responsemanagement libraries list -a --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment" | jq -r '.[] | select(.name == "'"$library"'") | .id' | tr -d '\r')
    fi

}

create_response() {
    payload=$(cat <<EOF
{
"name": "$name",
"libraries": [
{
    "id": "$library_id",
    "name": "$library"
}
],
"texts": [
{
    "content": "$content",
    "contentType": "text/html"
}
]
}
EOF
)
    echo "$payload" | gc responsemanagement responses create -i --clientid "$oauthclient_id" --clientsecret "$oauthclient_secret" --environment "$environment"

    if [[ $? -eq 0 ]]; then
        echo -e "\n\nResponse "$name" has been created...\n\n"
    else
        echo -e "\n\nSomething went wrong. Stopping here...Check pipeline logs...\n\n"
        exit 1
    fi
}

echo -e "Creating canned responses according to the CSV...\n\n"
echo -e "Some rows may contain bad html formatting. I will try to convert them properly...\n"

while IFS=";" read -r name library content
do

    check_and_create_library
    convert_html "$content"
    create_response

done <<< "$(tail -n +2 CreateCannedResponses.csv)"