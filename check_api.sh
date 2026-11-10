#!/bin/bash

URL=$1

if [ -z "$URL" ]; then
    echo "Использование: $0 <URL>"
    exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "API доступен"
    exit 0
else
    echo "API недоступен, код ответа: $HTTP_CODE"
    exit 1
fi
