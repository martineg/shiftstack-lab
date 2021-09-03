# To set up tests

* Install Vegeta test tool from https://github.com/tsenart/vegeta/releases
* Prepare an nginx deployment with different payload sizes
  ```
    oc apply -k nginx/
  ```

# Run tests

* Confirm default request rates and sizes set in _vegeta-run.sh_ and run the script giving the
  route where nginx is deployed as a parameter

```bash
$ oc get route -n my-ripsaw nginx -o json | jq -r '.spec.host'
nginx-my-ripsaw.apps.shiftstack.ocp4-on-osp.lab.martineg.net

$ bash vegeta-run.sh http://nginx-my-ripsaw.apps.shiftstack.ocp4-on-osp.lab.martineg.net
Attacking with 10 rps and response payload size 1024
Requests      [total, rate, throughput]         600, 10.02, 10.01
Duration      [total, attack, wait]             59.967s, 59.9s, 66.305ms
Latencies     [min, mean, 50, 90, 95, 99, max]  42.914ms, 58.274ms, 50.366ms, 77.756ms, 98.914ms, 168.76ms, 252.943ms
Bytes In      [total, mean]                     614400, 1024.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:600
Error Set:
Attacking with 10 rps and response payload size 4096

```

The test run will leave behind the set of vegeta raw logs (_*.bin_) used for the reports as well as latency plot diagrams (_*.html_)
