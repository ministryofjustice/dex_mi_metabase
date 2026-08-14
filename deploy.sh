#!/bin/sh

# exit when any command fails
set -e

p() {
  printf "\e[33m$1\e[0m\n"
}

function _deploy() {

  # Define variables for use in the script
  component=dex-mi
  context='live-1'

  # Single source of truth for the Metabase image tag, substituted into
  # kubernetes/${environment}/deployment.yaml below.
  export METABASE_VERSION=$(cat .metabase_version)

  usage="deploy -- deploy image from ECR to an environment
  Usage: ./deploy.sh environment
  Where:
    environment - one of staging|production
  Requires: kubectl, envsubst (part of the gettext package)
  Example:
    # build the app to get an image tag
    ./build.sh
    ...many lines of output...

    # deploy staging
    ./deploy.sh staging

    # deploy production
    ./deploy.sh production
    "

  # Ensure the script is called with two or three arguments
  if [ $# -lt 1 ]
  then
    echo "$usage"
    return 1
  fi
  
  # Ensure that the second argument is a valid stage
  case "$1" in
    staging | production)
      environment=$1
      ;;
    *)
      p "\e[31mFatal error: deployment environment not recognised: $2\e[0m"
      p "\e[31mEnvironment must be one of staging | production\e[0m\n"
      echo "$usage"
      return 1
      ;;
  esac

  # Ensure that the git-crypt secrets are unlocked ready for deployment
  if grep -rq "\x0GITCRYPT" kubernetes/$environment/secrets.yaml; then
    p "\e[31mFatal error: repository is locked with git-crypt\e[0m"
    p "\e[31mUnlock using 'git-crypt unlock'\e[0m\n"
    return 1
  fi


  namespace=$component-${environment}
  p "--------------------------------------------------"
  p "Deploying Metabase to kubernetes cluster: $context"
  p "Environment: \e[32m$environment\e[0m"
  p "Target namespace: \e[32m$namespace\e[0m"
  p "--------------------------------------------------"

  if [[ "$3" != "circleci" ]]
  then
    if [[ $environment == "production" ]]
    then
      read -p "Do you wish to deploy this image to production? (Enter 'deploy' to continue): " confirmation_message
      if [[ $confirmation_message == "deploy" ]]
      then
        p "Deploying app to production..."
      else
        return 0
      fi
    else
      read -p "Do you wish to deploy this image to $environment? (Enter Y to continue): " confirmation_message
      if [[ $confirmation_message =~ ^[Yy]$ ]]
      then
        p "Deploying app to $environment..."
      else
        return 0
      fi
    fi
  fi

  # Apply config map updates
  kubectl apply \
    -f kubernetes/${environment}/configmap.yaml -n $namespace

 # Apply non-image specific config
  secrets_arg=""
  if [ -f "kubernetes/${environment}/secrets.yaml" ]; then
    secrets_arg="-f kubernetes/${environment}/secrets.yaml"
  fi

  # deployment.yaml references ${METABASE_VERSION}; substitute it before applying
  envsubst '${METABASE_VERSION}' < kubernetes/${environment}/deployment.yaml | kubectl apply -f - -n $namespace

  kubectl apply \
    -f kubernetes/${environment}/service.yaml \
    -f kubernetes/${environment}/ingress-live.yaml \
    -f kubernetes/${environment}/secrets.yaml \
    -n $namespace
}

_deploy $@
