#! /bin/sh

pod_iterations=15
bench_namespace=cinder-csi-test
bench_suffix=$$
bench_resource_dir=resources/cinder-csi-bench-${bench_suffix}

wait_for_pods_run() {
  # Wait for pods to run
  echo "Waiting for all pods to run"
  for pod in $(oc get pod -n ${bench_namespace} -l benchmark=cinder-csi-bench-${bench_suffix} -o json | \
      jq -r '.items[] | .metadata.name'); do
          while :; do
              running_status=$(oc get pod -n ${bench_namespace} $pod \
              -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
              if [[ "$running_status" == "True" ]]; then
                  break
              else
                  sleep 1s;
              fi
          done
      echo "Pod $pod is running"
  done
}

# setup
[ -d ${bench_resource_dir} ] || mkdir -p ${bench_resource_dir}

oc create ns ${bench_namespace}

echo "Preparing resources"
for idx in $(seq 1 ${pod_iterations}); do
# create PVC definition

cat <<EOF > ${bench_resource_dir}/pvc-${idx}.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  labels:
    benchmark: cinder-csi-bench-${bench_suffix}
  name: data-${bench_suffix}-${idx}
  namespace: ${bench_namespace}
spec:
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard-csi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
EOF
cat <<EOF > ${bench_resource_dir}/deployment-${idx}.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    labels:
      benchmark: cinder-csi-bench-${bench_suffix}
      app: cinder-csi-bench-${bench_suffix}-${idx}
    name: cinder-csi-bench-${bench_suffix}-${idx}
    namespace: ${bench_namespace}
spec:
    progressDeadlineSeconds: 600
    replicas: 1
    revisionHistoryLimit: 10
    selector:
      matchLabels:
        app: cinder-csi-bench-${bench_suffix}-${idx}
    strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
    template:
      metadata:
        labels:
          benchmark: cinder-csi-bench-${bench_suffix}        
          app: cinder-csi-bench-${bench_suffix}-${idx}
          deploymentconfig: cinder-csi-bench-${bench_suffix}-${idx}
      spec:
        containers:
        - name: ubi-playground
          image: registry.redhat.io/ubi8
          args:
          - /bin/sh
          - -c
          - while true; do echo "hello cinder" | tee /data/log.txt && sleep 10 ;done
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8080
            protocol: TCP
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
          - mountPath: /data
            name: persistent-storage
        volumes:
        - name: persistent-storage
          persistentVolumeClaim:
            claimName: data-${bench_suffix}-${idx}
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        schedulerName: default-scheduler
        securityContext: {}
        terminationGracePeriodSeconds: 30
EOF
done
echo "Applying resources"
oc apply -f ${bench_resource_dir}

wait_for_pods_run

echo "All pods are running"
echo "Deleting pods"
oc delete pod -n ${bench_namespace} -l benchmark=cinder-csi-bench-${bench_suffix}

wait_for_pods_run
echo "All re-scheduled pods are running"