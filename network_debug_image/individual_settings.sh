#!/bin/bash

REGISTRY="registry-svc.default.svc.cluster.local"
PORT="5000"
SERVICE=$(basename $(pwd))
RUN_COMMAND='/bin/dash'
