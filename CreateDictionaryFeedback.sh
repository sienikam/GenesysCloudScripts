#!/bin/bash

set +x

while IFS=";" read -r term dialect soundsLike examplePhrases1 examplePhrases2 examplePhrases3 examplePhrases4 examplePhrases5
do
      echo "Term: $term"
      echo "Dialect: $dialect"
      echo "SoundsLike: $soundsLike"
      echo "examplePhrases1: $examplePhrases1"
      echo "examplePhrases2: $examplePhrases2"
      echo "examplePhrases3: $examplePhrases3"
      echo "examplePhrases4: $examplePhrases4"
      echo "examplePhrases5: $examplePhrases5"
      echo
      echo '{"term": "'"$term"'","dialect": "'"$dialect"'","boostValue": 2,"examplePhrases": [{"phrase": "'"$examplePhrases1"'","source": "Manual"},{"phrase": "'"$examplePhrases2"'","source": "Manual"},{"phrase": "'"$examplePhrases3"'","source": "Manual"},{"phrase": "'"$examplePhrases4"'","source": "Manual"},{"phrase": "'"$examplePhrases5"'","source": "Manual"}],"soundsLike": ["'"$soundsLike"'"]}' | gc speechandtextanalytics dictionaryfeedback create --clientid $oauthclient_id --clientsecret $oauthclient_secret --environment $environment
      if [ $? -eq 0 ]; then
          echo "Term: $term was created."
      fi
      echo
done <<< "$(tail -n +2 CreateDictionaryFeedback.csv)"