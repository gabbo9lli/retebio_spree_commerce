#!/bin/sh
set -e
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=2048}"

yarn build:api-client
yarn build:composables
yarn build:theme

export BACKEND_URL=$BACKEND_URL
cd packages/theme
exec yarn start --hostname 0.0.0.0 -p 3000
