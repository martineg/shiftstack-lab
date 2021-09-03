#! /bin/bash

# sizes served from nginx
#
# 2097152 1048576 524288  262144
# 131072  65536   32768   16384
# 8192    4096    2048    1024
#         512     256     128

rates=( 10 50 100 )         # req/s
sizes=( 1024 4096 16384 )   # bytes requested
duration=60

if [ $# -eq 0 ]; then
  echo "usage: $0 <endpoint root>"
  echo 
  echo "$0 http://nginx-my-nginx.apps.cluster.domain"
  exit 1
fi
endpoint_root=$1

vegeta_attack() {
  rate=$1
  size=$2
  output_bin=results-${rate}w-${size}b.bin

  vegeta attack \
    -targets targets.txt \
    -duration ${duration}s \
    -rate ${rate}/1s \
    -name ${rate}qps-${size}b \
    -insecure \
    | tee ${output_bin} | vegeta report
}

# cleanup
rm -f *.bin *.html

# vegeta
for rate in ${rates[@]}; do
  for size in ${sizes[@]}; do 
    echo "Attacking with $rate rps and response payload size $size"
    echo "GET ${endpoint_root}/${size}.html" > targets.txt
    vegeta_attack $rate $size
  done
done

# plot results
for f in *.bin; do
  vegeta plot $f > $(basename $f .bin).html
done
