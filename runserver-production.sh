#!/bin/bash

while true; do
  PG_STATUS=`PGPASSWORD=$DATABASE_PASSWORD psql -U $DATABASE_USER  -w -h $DATABASE_HOST -c '\l \q' | grep postgres | wc -l`
  if ! [ "$PG_STATUS" -eq "0" ]; then
   break
  fi

  echo "Waiting Database Setup"
  sleep 10
done

while true; do
  curl $DISCOURSE_UPSTREAM > /dev/null 2> /dev/null
  DISCOURSE_STATUS=$?

  if [[ "$DISCOURSE_STATUS" -eq "0" ]]; then
    break
  fi

  echo "Waiting Discourse Setup"
  sleep 10
done

PGPASSWORD=$DATABASE_PASSWORD psql -U $DATABASE_USER -w -h $DATABASE_HOST -c "CREATE DATABASE ${DATABASE_NAME} OWNER ${DATABASE_USER}"

npm rebuild node-sass --force
python3 src/manage.py migrate
python3 src/manage.py compress --force
python3 src/manage.py collectstatic --no-input
gunicorn edemocracia.wsgi:application --config=/var/labhacker/edemocracia/gunicorn.py
