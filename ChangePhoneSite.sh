#!/bin/bash
set +x
echo "Retrieving data from Genesys Cloud.."
PhoneList=`gc telephony providers edges phones list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
SiteList=`gc telephony providers edges sites list -a --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
while IFS=";" read -r name site
do
    echo "Name: $name"
    PhoneID=`echo "${PhoneList}" | jq -r '.[] | select(.name | test("'"^$name$"'";"i")) | .id' | tr -d '\r'`
    echo "PhoneID: $PhoneID"
    SiteID=`echo "${SiteList}" | jq -r '.[] | select(.name | test("'"^$site$"'";"i")) | .id' | tr -d '\r'`
    echo "SiteID: $SiteID"
    PhoneConfig=`gc telephony providers edges phones get $PhoneID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment`
    UpdatedPhoneConfig=$(echo "$PhoneConfig" | jq --arg siteId "$SiteID" --arg siteName "$site" '.site.id = $siteId | .site.name = $siteName ')
    echo $UpdatedPhoneConfig | gc telephony providers edges phones update $PhoneID --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
done <<< "$(tail -n +2 ChangePhoneSite.csv)"