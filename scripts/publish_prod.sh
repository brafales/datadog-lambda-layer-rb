#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2019 Datadog, Inc

set -e

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ $BRANCH != "master" ]; then
    echo "Not on master, aborting"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo 'AWS_ACCESS_KEY_ID not set. Are you using aws-vault?'
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo 'AWS_SECRET_ACCESS_KEY not set. Are you using aws-vault?'
    exit 1
fi

if [ -z "$AWS_SESSION_TOKEN" ]; then
    echo 'AWS_SESSION_TOKEN not set. Are you using aws-vault?'
    exit 1
fi

gem signin

./scripts/run_tests.sh

PACKAGE_VERSION=$(gem build datadog-lambda | grep Version | sed -n -e 's/^.*Version: //p')

echo 'Publishing to RubyGems'
gem push "datadog-lambda-${PACKAGE_VERSION}.gem"

echo 'Tagging Release'
git tag "v$PACKAGE_VERSION"
git push origin "refs/tags/v$PACKAGE_VERSION"

echo 'Publishing Lambda Layer'
./scripts/build_layers.sh
./scripts/publish_layers.sh
