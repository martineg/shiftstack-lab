#! /bin/bash

test_duration=1800 # 1800 seconds = 30 minutes

i=0
SECONDS=0
while true ; do
    DATE=$(date +'%H%M%S')

    echo "[$i] creating project ns-test-$DATE"
    oc new-project --skip-config-write=true ns-test-${DATE}
    oc new-app httpd:2.4-el8~https://github.com/sclorg/httpd-ex.git -n ns-test-${DATE}
    
    ((i++))
    sleep 5
    if [ $i -eq 10 ] ; then
        for proj in $(oc projects -q | grep 'ns-test-') ; do
            echo
            echo "[$i] deleting project: $proj"
            oc delete project "$proj"
            sleep 1
        done
        i=0
    fi
    if [[ $SECONDS -gt $test_duration ]]; then
      break
    fi
done

echo "Listing remaining namespaces"
oc get ns | grep ns-test
echo

echo "Listing remaining networks"
openstack network list | grep ns-test
echo

echo "Listing remaining subnets"
openstack subnet list | grep ns-test
echo
