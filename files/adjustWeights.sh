#!/bin/bash
#
if [ -r "/etc/profile.d/aws-apitools-common.sh" ]; then
  . /etc/profile.d/aws-apitools-common.sh
fi

# read env
ENVFILE=".env"

if [ -r "$ENVFILE" ]; then
  . $ENVFILE
else
  echo "${ENVFILE} not found, exiting."
  exit 1
fi

# read domains
RECORDSFILE=".records"

if [ ! -r "$RECORDSFILE" ]; then
  echo "${RECORDSFILE} not found, exiting."
fi

# determine region
if [ -z "$REGION" ]; then
  REGION=us-east-1
fi

AWS="aws --region $REGION"

TMPDIR=".tmp"
if [ ! -d "$TMPDIR" ]; then
  mkdir -p "$TMPDIR"
fi

for i in $(cat $RECORDSFILE); do
  CHANGEFILE="${TMPDIR}/change-${i}"
  TMPFILE=$(mktemp -t ${TMPDIR})

  # write changefile header
  cat > "$TMPFILE" <<CHANGEFILE_HEADER
  {
    "Comment": "setting weights Rimu: ${WEIGHT_RIMU} AWS: ${WEIGHT_AWS}",
    "Changes": [
CHANGEFILE_HEADER

  echo "Adjusting Rimu weight for '${i}'..."
  DOMAIN=$(echo -n "$i" | egrep -o '[[:alnum:]]+\.[[:alnum:]]+\.?$')

  if [ -z "$DOMAIN" ]; then
    echo "Unable to determine domain for record '${i}', exiting."
    exit 1
  else
    echo "Looking up zone ID for '${DOMAIN}'..."
  fi

  ZONE=$($AWS route53 list-hosted-zones-by-name --dns-name $DOMAIN --max-items 1)

  JQ_ZONE_ID_FILTER=$(echo -n ".HostedZones | map(select(.Name == \"" && echo -n "${DOMAIN}." && echo -n "\"))[] | .Id")
  ZONE_ID=$(echo "$ZONE" | jq -r "$JQ_ZONE_ID_FILTER")

  if [ -z "$ZONE_ID" ]; then
    echo "Unable to determine zone ID for domain '${DOMAIN}', exiting."
    exit 1
  else
    echo "Found zone ID '${ZONE_ID}' for domain '${DOMAIN}'."
  fi

  RECORDS=$($AWS route53 list-resource-record-sets --hosted-zone-id ${ZONE_ID})
  if [ -z "$RECORDS" ]; then
    echo "No resource records found for domain '${DOMAIN}', exiting."
    exit 1
  else
    echo "Retrieved resource records for domain '${DOMAIN}'."
  fi

  JQ_RIMU_CHANGE_FILTER=$(echo -n ".ResourceRecordSets | map(select(.Type == \"A\")) | map(select(.SetIdentifier == \"" && echo -n "${i}-Rimu" && echo -n "\")) | map(. + {Weight: ${WEIGHT_RIMU}})[0] | {ResourceRecordSet: .} + {Action: \"UPSERT\"}")
  RIMU_CHANGE=$(echo "$RECORDS" | jq "$JQ_RIMU_CHANGE_FILTER")

  JQ_AWS_CHANGE_FILTER=$(echo -n ".ResourceRecordSets | map(select(.Type == \"A\")) | map(select(.SetIdentifier == \"" && echo -n "${i}-AWS" && echo -n "\")) | map(. + {Weight: ${WEIGHT_AWS}})[0] | {ResourceRecordSet: .} + {Action: \"UPSERT\"}")
  AWS_CHANGE=$(echo "$RECORDS" | jq "$JQ_AWS_CHANGE_FILTER")

  # write the change for each record
  echo -n "$RIMU_CHANGE" >> "$TMPFILE"
  echo "," >> "$TMPFILE"
  echo "$AWS_CHANGE" >> "$TMPFILE"

  # write changefile footer
  cat >> "$TMPFILE" <<CHANGEFILE_FOOTER
    ]
  }
CHANGEFILE_FOOTER

  # clean up formatting
  cat "$TMPFILE" | jq . > "$CHANGEFILE"

  if [ -r "$CHANGEFILE" ]; then
    CHANGE_BATCH=$(cat "${CHANGEFILE}" | jq -c .)
  else
    echo "Unable to read changefile '${CHANGEFILE}', exiting."
    exit 1
  fi

  ROUTE53_CMD="$AWS route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch '${CHANGE_BATCH}'"

  if [ "$WEIGHT_REALLY_FOR_REALS" = "yes really i mean it" ]; then
    CHANGE_INFO=$(eval $ROUTE53_CMD)

    CHANGE_ID=$(echo "$CHANGE_INFO" | jq -r '.ChangeInfo.Id')
    CHANGE_STATUS=$(echo "$CHANGE_INFO" | jq -r '.ChangeInfo.Status')

    while [ "$CHANGE_STATUS" != 'INSYNC' ]; do
      sleep 5;
      CHANGE_INFO=$($AWS route53 get-change --id ${CHANGE_ID})
      CHANGE_STATUS=$(echo "$CHANGE_INFO" | jq -r '.ChangeInfo.Status')
      echo "Status of change '${CHANGE_ID}' is '${CHANGE_STATUS}' at $(date)."
    done

    echo "$CHANGE_INFO" | jq .
  else
    echo $ROUTE53_CMD
    cat $CHANGEFILE
  fi

done
