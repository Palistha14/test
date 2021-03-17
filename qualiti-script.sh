 
    set -ex
    
    PROJECT_ID='332'
    API_KEY='lmXpjbDU5o9NoYM1lK80N9yte4JiB0Hqacm0hxTB'
    CLIENT_ID='81ffb5adbbd7fa4d3224a15c2d4ca20f'
    SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
    API_URL='https://7iggpnqgq9.execute-api.us-east-2.amazonaws.com/udbodh/api'
    INTEGRATION_JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9qZWN0X2lkIjozMzIsImFwaV9rZXlfaWQiOjE3ODgsIm5hbWUiOiIiLCJkZXNjcmlwdGlvbiI6IiIsImljb24iOiIiLCJpbnRlZ3JhdGlvbl9uYW1lIjoiQ2lyY2xlY2kiLCJvcHRpb25zIjp7fSwiaWF0IjoxNjE1ODAwMzg5fQ.xop8zsjCp44clIk2WdHkNxBLDV0UIAbcnlskR7TSEzY'
    INTEGRATIONS_API_URL='http://075be6ef4985.ngrok.io'
       
    sudo apt-get update -y
    sudo apt-get install -y jq
    
    #Trigger test run
    TEST_RUN_ID="$( \
      curl -X POST -G ${INTEGRATIONS_API_URL}/api/integrations/circleci/${PROJECT_ID}/events \
        -d 'token='$INTEGRATION_JWT_TOKEN''\
        -d 'triggerType=Deploy'\
      | jq -r '.test_run_id')"
    
    AUTHORIZATION_TOKEN="$( \
      curl -X POST -G ${API_URL}/auth/token \
      -H 'x-api-key: '${API_KEY}'' \
      -H 'client_id: '${CLIENT_ID}'' \
      -H 'scopes: '${SCOPES}'' \
      | jq -r '.token')"
    
    # Wait until the test run has finished
    while : ; do
      RESULT="$( \
      curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
      | jq -r '.[0].finished')"
      if [ "$RESULT" != null ]; then
        break;
      fi
        sleep 15;
    done
    
    # # Once finished, verify the test result is created and that its passed
    TEST_RUN_RESULT="$( \
      curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
        -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
        -H 'x-api-key: '${API_KEY}'' \
      | jq -r '.[0].status' \
    )"
    echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
      displayName: "Initialize Environment"
