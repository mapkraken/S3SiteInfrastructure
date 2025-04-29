#!/bin/bash -xe
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:UserDataHash,Values=v0.6" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["#!/bin/bash","echo '\''Updated script'\'' >> /tmp/userdata-test.log"]}'