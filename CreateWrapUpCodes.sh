#!/bin/bash

set +x

while IFS=";" read -r column1
do
  echo "Wrap-Up Code: $column1"
  echo '{"name": "'"$column1"'"}' | tr -d '\r' | gc routing wrapupcodes create --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
  echo "Wrap-Up Code: $column1 created.." | tr -d '\r'
done <<< "$(tail -n +2 CreateWrapUpCodes.csv)"
