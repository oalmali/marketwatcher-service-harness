#!/bin/bash

#### Initial setup
DIR=`dirname $(readlink -f $0)`
OLDPWD=`pwd`

#### Check required parameters
if [[ -z "${COMPOSE_PROJECT_NAME}" ]]; then
    echo "COMPOSE_PROJECT_NAME must be set to a correct value"
	exit -1
fi

#### Go to service's directory
cd $DIR/../../

echo "Configuring ecs-cli"

ecs-cli configure \
	--region us-west-1 \
	--cluster default \
	--compose-project-name-prefix "" \
	--compose-service-name-prefix ""

CONFIGURE_RESULT=$?
if [[ $CONFIGURE_RESULT -ne 0 ]]; then
	echo "Could not configure ECS CLI"
	exit $CONFIGURE_RESULT
fi

echo "Checking if there's an existing service definition, bringing down if necessary"
ecs-cli ps | grep "${COMPOSE_PROJECT_NAME}" | grep "RUNNING"

EXISTING_SERVICE_CHECK_RESULT=$?
if [[ $EXISTING_SERVICE_CHECK_RESULT -eq 0 ]]; then
	echo "Same service definition exists in EC2. Bringing service DOWN"

	ecs-cli compose --file docker-compose.yml service down

	DOWN_RESULT=$?
	if [ $DOWN_RESULT -ne 0 ]; then
		echo "Could not bring service DOWN"
		exit $DOWN_RESULT
	fi

	echo "Sleeping for 30 seconds"

	sleep 30
fi

echo "Bringing new service definition up"
ecs-cli compose --file docker-compose.yml service up

UP_RESULT=$?
if [[ $UP_RESULT -ne 0 ]]; then
	echo "Could not bring service UP in ECS"
	exit $UP_RESULT
fi

echo "Going back to original directory"
cd $OLDPWD

echo "Deployment Done"
