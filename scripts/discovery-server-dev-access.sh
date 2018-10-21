#!/usr/bin/env bash

printf "\n Setting up port forwarding to discovery server ...\n"

export APP_POD_NAME=$(kubectl get pods -l "role=discovery-server" -o jsonpath="{.items[0].metadata.name}" --namespace=development)
kubectl port-forward $APP_POD_NAME 8761:8761 --namespace=development>> /dev/null &

printf "\nPort forwarding OK"