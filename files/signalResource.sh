#!/bin/bash
#
# Signal our AutoScaling group that we're ready to be in service.

set -o nounset

INSTANCE=$(curl http://169.254.169.254/latest/meta-data/instance-id/ 2>/dev/null)
ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone/ 2>/dev/null)
REGION=$(echo "${ZONE}" | sed 's/[[:alpha:]]$//')
AWS="aws --region ${REGION}"

STACK=$(${AWS} ec2 describe-tags --filter "Name=resource-id,Values=${INSTANCE}" "Name=key,Values=aws:cloudformation:stack-name" "Name=resource-type,Values=instance" | jq -r '.Tags[0].Value')

ASG=$(${AWS} ec2 describe-tags --filter "Name=resource-id,Values=${INSTANCE}" "Name=key,Values=aws:autoscaling:groupName" "Name=resource-type,Values=instance" | jq -r '.Tags[0].Value')

RESOURCE=$(${AWS} cloudformation describe-stack-resources --stack-name ${STACK} | jq -r ".StackResources[] | select(.PhysicalResourceId == \"${ASG}\") | .LogicalResourceId")

cfn-signal --region="${REGION}" --stack="${STACK}" --resource="${RESOURCE}"
