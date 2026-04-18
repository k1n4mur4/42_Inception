#!/bin/bash

host="$1"
port="$2"

while ! nc -z "$host" "$port"; do
    echo "Waiting for $host:$port..."
    sleep 1
done

echo "$host:$port is available!"