#! /bin/bash

root_path=/data
root_levels=10
leaf_levels=101

for idx in $(seq 1 ${root_levels}); do
    mkdir d${idx} && cd d${idx}
    for subidx in $(seq 1 ${leaf_levels}); do
        curdir=d${idx}-${subidx}
        mkdir $curdir && cd $curdir
    done
    cd /${root_path}
done

ls -lR ${root_path}
