#!/bin/bash -x

echo "creating project ubi-playground"
oc new-project --skip-config-write=true ubi-playground

i=0
j=0

while true ; do
DATE=$(date +"%H%M%S")
echo "creating ubi-playground-$j-$DATE deployment and pvc"
cat <<EOF | oc create -f - -n ubi-playground
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: ubi-playground-$j-$DATE
    namespace: ubi-playground
spec:
    accessModes:
    - ReadWriteOnce
    resources:
        requests:
            storage: 1Gi
    storageClassName: standard-csi
---
apiVersion: apps/v1
kind: Deployment
metadata:
    labels:
      app: ubi-playground-$j-$DATE
    name: ubi-playground-$j-$DATE
    namespace: ubi-playground
spec:
    progressDeadlineSeconds: 600
    replicas: 1
    revisionHistoryLimit: 10
    selector:
      matchLabels:
        app: ubi-playground-$j-$DATE
    strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
    template:
      metadata:
        labels:
          app: ubi-playground-$j-$DATE
          deploymentconfig: ubi-playground-$j-$DATE
      spec:
        containers:
        - name: ubi-playground
          image: registry.redhat.io/ubi8
          args:
          - /bin/sh
          - -c
          - while true; do echo "hello ubi-playground" && sleep 10 ;done
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8080
            protocol: TCP
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
          - mountPath: /mnt/playground
            name: persistent-storage
        volumes:
        - name: persistent-storage
          persistentVolumeClaim:
          claimName: ubi-playground-$j-$DATE
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        schedulerName: default-scheduler
        securityContext: {}
        terminationGracePeriodSeconds: 30
EOF
    ((i++))
    sleep 5
    if [ $i -eq 10 ] ; then
    sleep 5
    for up in $(oc get deployment -n ubi-playground --no-headers=true | grep ubi-playground-$j- | awk '{ print $1 }') ; do
        echo
        echo "[$i] deleting deployment: $up"
        oc delete deployment $up -n ubi-playground
        echo
        echo "[$i] deleting pvc: $up"
        oc delete pvc $up -n ubi-playground
        sleep 1
    done
    i=0
    ((j++))
    fi
done