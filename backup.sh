#!/bin/sh

NOW=$(date +"%Y-%m-%dT%H:%M:%SZ")
FILE="/backups/$NOW.sql.gz"

echo "Creating dump of ${MYSQL_DATABASE} database from ${DB_HOST}..."
TEMP_FILE=$(mktemp)
mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD --port=$MYSQL_PORT $MYSQL_DATABASE > $TEMP_FILE || exit 4
cat $TEMP_FILE | gzip > $FILE || exit 
echo "SQL backup successfull"

if [ ! -z "$BUCKET" ]; then
  echo "Uploading dump to $BUCKET"
  # export AWS_ACCESS_KEY_ID
  # export AWS_SECRET_ACCESS_KEY
  # export AWS_DEFAULT_REGION
  cat $FILE | aws $AWS_ARGS s3 cp - s3://$BUCKET/$PREFIX/${MYSQL_DATABASE}_${NOW}.sql.gz || exit 2
  echo "SQL backup uploaded successfully"
fi

if [ ! -z "$MAIL_TO" ]; then
  echo "Sending mail to $MAIL_TO"
  swaks --header "Subject:Backup of ${MYSQL_DATABASE} database successfull at ${NOW}" \
        --from $MAIL_FROM \
        --server "${MAIL_HOST}" \
        --port "${MAIL_PORT}" \
        --auth LOGIN \
        --auth-user "${MAIL_USER}" \
        --auth-password "${MAIL_PASSWORD}" \
        --to "$MAIL_TO" \
        --body "Automated backups " \
        --attach $FILE || exit 5
fi
