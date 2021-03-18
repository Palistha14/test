#!/bin/bash
 
set -ex
 
PROJECT_ID='332'
API_KEY='nKrOmTdoX44ss9YhOuJlb2fE7218lw6w65kJAHRs'
CLIENT_ID='5b2e66ea6f2b3d6282c693cdb264cea4'
SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
API_URL='https://7iggpnqgq9.execute-api.us-east-2.amazonaws.com/udbodh/api'
INTEGRATION_JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9qZWN0X2lkIjozMzIsImFwaV9rZXlfaWQiOjIyNzgsIm5hbWUiOiIiLCJkZXNjcmlwdGlvbiI6IiIsImljb24iOiIiLCJpbnRlZ3JhdGlvbl9uYW1lIjoiQ2lyY2xlY2kiLCJvcHRpb25zIjp7fSwiaWF0IjoxNjE2MDQyMjU4fQ.AgrNFifnYDUIC8Vt6wY18qJtcB_XMa51PfJnW41nY14'
INTEGRATIONS_API_URL='http://9f960070d582.ngrok.io'
 
# sudo apt-get update -y
# sudo cp -p /etc/apt/sources.list{,.back}
# sudo apt-get -o Acquire::Check-Valid-Until=false update
sudo sed -i '/jessie-backports/d' /etc/apt/sources.list 
sudo sed -i '/jessie-updates/d' /etc/apt/sources.list ZZ
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