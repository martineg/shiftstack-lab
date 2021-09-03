#! /bin/bash

benchmark_script_root=$(pwd)/benchmarks
benchmark_file=${benchmark_script_root}/kube-burner-max-namespaces-benchmark.yaml
benchmark_ns=my-ripsaw
benchmark_iterations=10

get_benchmark_suuid() {
    benchmark_suuid=$(oc get -n ${benchmark_ns} benchmark ${benchmark_name} -o yaml | yq e '.status.suuid' -)
    echo $benchmark_suuid
}

get_benchmark_state() {
    benchmark_state=$(oc get -n ${benchmark_ns} benchmark ${benchmark_name} -o yaml | yq e '.status.state' -)
    echo $benchmark_state
}
for iteration in $(seq $benchmark_iterations); do
    benchmark_name=$(yq eval '.metadata.name' ${benchmark_file})

    SECONDS=0
    echo "Starting benchmark ${benchmark_name} - iteration ${iteration}"
    oc apply -n ${benchmark_ns} -f ${benchmark_file}

    benchmark_suuid=$(get_benchmark_suuid)
    while [[ "$benchmark_suuid" =  "" ]] || [[ "$benchmark_suuid" = "null" ]]; do
        benchmark_suuid=$(get_benchmark_suuid)
    done

    echo "Waiting for benchmark ${benchmark_name} (${benchmark_suuid}) to complete"
    benchmark_state=$(get_benchmark_state)
    while [[ $benchmark_state != "Complete" ]]; do
        benchmark_state=$(get_benchmark_state)
    done

    echo "Cleaning up ${benchmark_name} (${benchmark_suuid})"
    oc delete -n ${benchmark_ns} -f ${benchmark_file}

    duration=$SECONDS
    echo "Benchmark ${benchmark_name} done in $(($duration / 60)) minutes and $(($duration % 60)) seconds"
done

# cleanup
# oc get ns | awk '$1 ~ /max-namespaces/ {print $1}' | xargs oc delete ns
# openstack network list | grep max-namespaces