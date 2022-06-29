#!/bin/bash

  set -ex

  API_KEY='931e71501f92a4b6'
  INTEGRATIONS_API_URL='https://3000-qualitiai-qualitiapi-pzncy7t3jqu.ws-us47.gitpod.io'
  PROJECT_ID='1788'
  CLIENT_ID='cf7ea70b67ecd943a29987886939571d'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-pzncy7t3jqu.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='50c9963a17273bf1ca7c821eb9a3c354ae2709984fd100591c774ed29090c5c34ba7bcaec29decea462ea17239eef3e8c2718cfbf2e2b7cd38a7837c162457f4a498756dee9f9718df772a22d4dcb074d1ef27f9ff24e396954663e35a158aef5da4fc02a30ac229084080499ce833134412e3d3717c7c1e9770fea99d3b88d7d63580550d4c340205260f3bf50e52bd690da1cebdabeea57fc873093b8aa0f3dd9eed1cb0f4c60f3887bbb9d13c93d7221c34a92dc4a1c1f2501c75c1c7ec35401181ab42c66dcd3476eb75fc6fa0def188c41b48855f22fe21ba6df31d649643c81bc1cabdfa0b96236d54760c6a5d5838782ecfa4c1e84c03ab9f79fb75eb25cd3dc40d62909398e0416c7b0553d4|12d0905e178470846291e8c6dff9d0a4|27421f1f8a30e7f0f520f92b2020543b'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/circleci/${PROJECT_ID}/events \
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
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
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
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
