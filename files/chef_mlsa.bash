#!/usr/bin/env bash
case ${1,,} in
  true)  exit 0 ;;

  1)     exit 0 ;;

  false) echo "Please set acept_license = \"true\" in terraform.tfvars"
         exit 1 ;;

  0)     echo "Please set acept_license = \"true\" in terraform.tfvars"
         exit 1 ;;

  *)     echo "Please set acept_license = \"true\" in terraform.tfvars"
         exit 1 ;;
esac
