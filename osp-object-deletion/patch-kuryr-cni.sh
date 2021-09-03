#! /bin/bash

case "$1" in
  debug)
    oc patch network.operator cluster -p '{"spec":{"logLevel":"Debug"}}' --type=merge
    ;;
  normal)
    oc patch network.operator cluster -p '{"spec":{"logLevel":"Normal"}}' --type=merge
    ;;
  *)
    exit 0
    ;;
esac
