#!/bin/bash
set -euo pipefail

suffix="${SUFFIX}"
domain="${ACCOUNT_ALIAS}.acurisbackend.com"
ip=$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.Networks[0].IPv4Addresses[0]')
service_name=$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.TaskDefinitionFamily')

record_name="${service_name}-${suffix}.${domain}"
echo "Record name to be created: '$record_name'"
hosted_zones=$(aws route53 list-hosted-zones)
# echo $hosted_zones
hosted_zone_id=$(echo "$hosted_zones" | jq -r ".HostedZones[] | select(.Name == \"${domain}.\") | .Id")
echo "Route53 hosted zone id: '$hosted_zone_id', for domain '${domain}'"

change_batch_template="{
  \"Comment\": \"Update record for ${record_name}\",
  \"Changes\": [{
  \"Action\": \"UPSERT\",
    \"ResourceRecordSet\": {
      \"Name\": \"${record_name}\",
      \"Type\": \"A\",
      \"TTL\": 10,
      \"ResourceRecords\": [{ \"Value\": \"${ip}\"}]
}}]
}"

change_info=$(aws route53 change-resource-record-sets --hosted-zone-id "${hosted_zone_id}" --change-batch "${change_batch_template}")
# echo $change_info
change_info_id=$(echo $change_info | jq -r '.ChangeInfo.Id')
echo "Route 53 change info id: '$change_info_id', used to confirm the changes have been made"

change_info_status=$(aws route53  get-change --id "${change_info_id}" | jq -r '.ChangeInfo.Status')
while [ "$change_info_status" != "INSYNC" ]; do
 echo "DNS update not yet in sync (${change_info_status}), waiting and trying again"
 sleep 5
 change_info_status=$(aws route53  get-change --id "${change_info_id}" | jq -r '.ChangeInfo.Status')
done
