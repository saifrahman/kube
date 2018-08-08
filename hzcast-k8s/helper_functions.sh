print_help(){
  echo -e "${YELLOW}Use the following Command:"
  echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo -e "${RED}./<script-name> --action <action-name> --deployment <deployment-name> --scaleup <scaleupthreshold> --scaledown <scaledownthreshold>"
  echo -e "${YELLOW}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  printf "Choose one of the available actions below:\n"
  printf " get-heapmemory\n get-podmemory\n deploy-heap-autoscaling\n deploy-pod-autoscaling\n"
  echo -e "You can get the list of existing deployments using command: kubectl get deployments${NONE}"
}

#########################################
#defining function to calculate heap memory

calculate_heap(){
  echo "===========================" >> $LOG_FILE
  pods=`$KUBECTL get pod -l name=$DEPLOYMENT | awk '{print $1}' | grep -v NAME`
  for i in $pods
    do
      echo "Pod: "$i >> $LOG_FILE

      PID=`$KUBECTL exec -it $i -- ps -ef | grep -v grep | grep java | awk '{print $2}'` >> $LOG_FILE

      TOTALHEAP=`$KUBECTL exec -t $i -- ps -ef | grep java | grep -v grep  | awk -F'Xmx' '{print $2}' | awk '{print $1}' | grep -o '[0-9]\+[a-z]'`

      if [[ $TOTALHEAP =~ .*g.* ]]; then
         TOTALHEAPINGB=${TOTALHEAP//[!0-9]/}
         TOTALHEAPINMB=$((TOTALHEAPINGB * 1024))
         echo "Total Heap Capacity Allocated: "$TOTALHEAPINMB"MB" >> $LOG_FILE
      elif [[ $TOTALHEAP =~ .*m.* ]]; then
         TOTALHEAPINMB=${TOTALHEAP//[!0-9]/}
         echo "Total Heap Capacity Allocated: "$TOTALHEAPINMB"MB" >> $LOG_FILE
      fi

      USEDHEAP=`$KUBECTL exec -it $i -- jstat -gc $PID  | tail -n 1 | awk '{ print ($3 + $4 + $6 + $8 + $10) / 1024 }'`
      echo "Used Heap Memory: "$USEDHEAP"MB" >> $LOG_FILE

      UTILIZEDHEAP=$(awk "BEGIN { pc=100*${USEDHEAP}/${TOTALHEAPINMB}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
      echo "Heap memory Percent: "$UTILIZEDHEAP"%" >> $LOG_FILE

      heapmem=$((heapmem+UTILIZEDHEAP))
      echo "===========================" >> $LOG_FILE
    done
  AVGHEAPMEM=$(( $heapmem/$REPLICAS ))
  echo "Average Heap Memory: "$AVGHEAPMEM >> $LOG_FILE
}

#########################################
#defining function to autoscale based on heap memory

heapmemory_autoscale(){
  if [ $AVGHEAPMEM -gt $SCALEUPTHRESHOLD ]
  then
      echo "Memory is greater than the threshold" >> $LOG_FILE
      count=$((REPLICAS+1))
      echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Up" >> $LOG_FILE

  elif [ $AVGHEAPMEM -lt $SCALEDOWNTHRESHOLD ] && [ $REPLICAS -gt 2 ]
  then
      echo "Memory is less than threshold" >> $LOG_FILE
      count=$((REPLICAS-1))
      echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Down" >> $LOG_FILE
  else
      echo "Heap Memory is not crossing the threshold. No Scaling Done." >> $LOG_FILE
  fi
}

##########################################
#defining function to calculate pod memory

calculate_podmemory(){
pods=`$KUBECTL top pod |grep $DEPLOYMENT | awk '{print $3}' | grep -o '[0-9]\+'`
podnames=`$KUBECTL get pods|grep $DEPLOYMENT | awk '{print $1}' | grep -v NAME`

TOTALMEM=`$KUBECTL describe pod -l name=$DEPLOYMENT | grep -A 2 "Limits:" | grep memory | grep -o '[0-9]\+[A-Z]' | head -1`
if [[ $TOTALMEM =~ .*G.* ]]; then
    TOTALMEMINGB=${TOTALMEM//[!0-9]/}
    TOTALMEMINMB=$((TOTALMEMINGB * 1024))
    echo "Total Pod Memory Allocated: "$TOTALMEMINMB"MB" >> $LOG_FILE
    echo "===========================" >> $LOG_FILE
elif [[ $TOTALMEM =~ .*M.* ]]; then
    TOTALMEMINMB=${TOTALMEM//[!0-9]/}
    echo "Total Pod Memory Allocated: "$TOTALMEMINMB"MB" >> $LOG_FILE
    echo "===========================" >> $LOG_FILE
fi

for i in $pods
do
  podmem=$((podmem+i))
  echo "Used Pod Memory: "$podmem >> $LOG_FILE
  UTILIZEDPODMEM=$(awk "BEGIN { pc=100*${podmem}/${TOTALMEMINMB}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  echo "Pod memory Percent: "$UTILIZEDPODMEM"%" >> $LOG_FILE
  echo "===========================" >> $LOG_FILE
done
AVGPODMEM=$(( $UTILIZEDPODMEM/$REPLICAS ))
echo "Average Pod Memory: "$AVGPODMEM >> $LOG_FILE
}

##########################################
#defining function to autoscale based on pod memory

podmemory_autoscale(){
  if [ $AVGPODMEM -gt $SCALEUPTHRESHOLD ]
  then
    echo "Memory is greater than threshold" >> $LOG_FILE
    count=$((REPLICAS+1))
    echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
    scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
    echo "Deployment Scaled Up" >> $LOG_FILE

  elif [ $AVGPODMEM -lt $SCALEDOWNTHRESHOLD ] && [ $REPLICAS -gt 2 ]
  then
    echo "Memory is less than threshold" >> $LOG_FILE
    count=$((REPLICAS-1))
    echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
    scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
    echo "Deployment Scaled Down" >> $LOG_FILE
  else
    echo "Memory is not crossing the threshold. No Scaling done." >> $LOG_FILE
  fi
}

calculate_podmemory(){
pods=`$KUBECTL top pod $1| awk '{print $3}' | grep -o '[0-9]\+'`


TOTALMEM=`$KUBECTL describe $1 | grep -A 2 "Limits:" | grep memory | grep -o '[0-9]\+[A-Z]' | head -1`
if [[ $TOTALMEM =~ .*G.* ]]; then
    TOTALMEMINGB=${TOTALMEM//[!0-9]/}
    TOTALMEMINMB=$((TOTALMEMINGB * 1024))
    echo "Total Pod Memory Allocated: "$TOTALMEMINMB"MB" >> $LOG_FILE
    echo "===========================" >> $LOG_FILE
elif [[ $TOTALMEM =~ .*M.* ]]; then
    TOTALMEMINMB=${TOTALMEM//[!0-9]/}
    echo "Total Pod Memory Allocated: "$TOTALMEMINMB"MB" >> $LOG_FILE
    echo "===========================" >> $LOG_FILE
fi

for i in $pods
do
  podmem=$((podmem+i))
  echo "Used Pod Memory: "$podmem >> $LOG_FILE
  UTILIZEDPODMEM=$(awk "BEGIN { pc=100*${podmem}/${TOTALMEMINMB}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  echo "Pod memory Percent: "$UTILIZEDPODMEM"%" >> $LOG_FILE
  echo "===========================" >> $LOG_FILE
done
AVGPODMEM=$(( $UTILIZEDPODMEM/$REPLICAS ))
echo "Average Pod Memory: "$AVGPODMEM >> $LOG_FILE
}
