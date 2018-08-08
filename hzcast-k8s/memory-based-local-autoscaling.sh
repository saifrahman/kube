#!/bin/bash
. ./helper_functions.sh
##########################################
#setup
heapmem=0
podmem=0
TODAY=`date +%F`
KUBECTL=/usr/local/bin/kubectl
SCRIPT_HOME=/Users/sur000e/workspace-kube/hzcast-k8s/logs
if [ ! -d $SCRIPT_HOME ]; then
  mkdir -p $SCRIPT_HOME
fi
LOG_FILE=$SCRIPT_HOME/kube-$TODAY.log
touch $LOG_FILE
RED='\033[01;31m'
YELLOW='\033[0;33m'
NONE='\033[00m'
ARG="$#"
if [[ $ARG -eq 0 ]]; then
  print_help
  exit
fi

while test -n "$1"; do
   case "$1" in
        --action)
            ACTION=$2
            shift
            ;;
        --deployment)
            DEPLOYMENT=$2
            shift
            ;;
        --scaleup)
            SCALEUPTHRESHOLD=$2
            shift
            ;;
        --scaledown)
            SCALEDOWNTHRESHOLD=$2
            shift
            ;;
       *)
            print_help
            exit
            ;;
   esac
    shift
done

LOG_FILE=$SCRIPT_HOME/kube-$DEPLOYMENT-$TODAY.log
touch $LOG_FILE

echo "$ACTION:$DEPLOYMENT"

REPLICAS=`$KUBECTL get deployments |grep $DEPLOYMENT | awk '{print $3}' | grep -v "CURRENT"`
echo "$REPLICAS"

##########################################
#Calling Functions
if [[ $REPLICAS ]]; then
  if [ "$ACTION" = "deploy-heap-autoscaling" ];then
      if [ $ARG -ne 8 ]
      then
        echo "Incorrect No. of Arguments Provided"
        print_help
        exit 1
      fi
      calculate_heap
      heapmemory_autoscale
  elif [ "$ACTION" = "get-heapmemory" ];then
      if [ $ARG -ne 4 ]
      then
        echo "Incorrect No. of Arguments Provided"
        print_help
        exit 1
      fi
      calculate_heap
  elif [ "$ACTION" = "get-podmemory" ];then
      if [ $ARG -ne 4 ]
      then
        echo "Incorrect No. of Arguments Provided"
        print_help
        exit 1
      fi
      calculate_podmemory
  elif [ "$ACTION" = "deploy-pod-autoscaling" ];then
      if [ $ARG -ne 8 ]
      then
        echo "Incorrect No. of Arguments Provided"
        print_help
        exit 1
      fi
      calculate_podmemory
      podmemory_autoscale
  else
      echo "Unknown Action"
      print_help
  fi
else
  echo "No Deployment exists with name: "$DEPLOYMENT
  print_help
fi
