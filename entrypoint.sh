#!/bin/sh

set -e

# Jsonnet validation & arg wrangling
if [ -z "$ARG_OUTPUT_DIR" ]
then
  echo "Must specify ARG_OUTPUT_DIR env var"
  exit 1
else
  if [ ! -d "$ARG_OUTPUT_DIR" ] 
  then
    mkdir -p $ARG_OUTPUT_DIR
  fi
  OUTPUT_DIR="-m $ARG_OUTPUT_DIR"
fi

if [ -z "$INPUT_PARAMS" ]
then
  EXTERNAL_PARAMS_ARG=""
else
  INPUT_PARAMS=$(echo $INPUT_PARAMS | sed 's/[,;]/ /g')
  EXTERNAL_PARAMS_ARG=""
  for PARAM in $INPUT_PARAMS
  do
    EXTERNAL_PARAMS_ARG="$EXTERNAL_PARAMS_ARG --ext-str $PARAM"
  done
fi

# Allow for a delimited list of input files
if [ -z "$INPUT_FILE" ]
then
  echo "Must specify INPUT_FILE env var"
  exit 1
else
  INPUT_FILES=$(echo $INPUT_FILE | sed 's/[,;]/ /g')
  for FILE in $INPUT_FILES
  do
    echo "Running jsonnet $EXTERNAL_PARAMS_ARG $OUTPUT_DIR $FILE"
    jsonnet $EXTERNAL_PARAMS_ARG $OUTPUT_DIR $FILE
  done
fi

# Once generated, login w/ kubectl & then apply the generated output
if [ ! -z "${KUBE_CONFIG}" ]; then
    mkdir -p $HOME/.kube
    echo "$KUBE_CONFIG" | base64 -d > $HOME/.kube/config
else
    echo "No KUBE_CONFIG found. Please provide one. Exiting..."
    exit 1
fi

kubectl apply -f $ARG_OUTPUT_DIR