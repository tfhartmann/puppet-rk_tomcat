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

CHANGEFILE="${TMPDIR}/change"

# write changefile header
cat > "$CHANGEFILE" <<CHANGEFILE_HEADER
{
  "Comment": "setting weights Rimu: ${WEIGHT_RIMU} AWS: ${WEIGHT_AWS}",
  "Changes": [
CHANGEFILE_HEADER

for i in $(cat $RECORDSFILE); do
  echo "Adjusting weight for '${i}'..."
  DOMAIN=$(echo -n "$i" | egrep -o '[[:alnum:]]+\.[[:alnum:]]+\.?$')

  if [ -z "$DOMAIN" ]; then
    echo "Unable to determine domain for record '${i}', exiting."
    exit 1
  else
    echo "Looking up zone ID for '${DOMAIN}'..."
  fi

  JQ_FILTER=$(echo -n ".HostedZones | map(select(.Name == \"" && echo -n "${DOMAIN}." && echo -n "\"))[] | .Id")
  ZONE_ID=$($AWS route53 list-hosted-zones-by-name --dns-name $DOMAIN --max-items 1 | jq -r "$JQ_FILTER")

  if [ -z "$ZONE_ID" ]; then
    echo "Unable to determine zone ID for domain '${DOMAIN}', exiting."
    exit 1
  else
    echo "Found zone ID '${ZONE_ID}' for domain '${DOMAIN}'."
  fi

done

# write changefile footer
cat >> "$CHANGEFILE" <<CHANGEFILE_FOOTER
  ]
}
CHANGEFILE_FOOTER

if [ -r "$CHANGEFILE" ]; then
  cat "${CHANGEFILE}"
else
  echo "Unable to read changefile '${CHANGEFILE}', exiting."
  exit 1
fi
