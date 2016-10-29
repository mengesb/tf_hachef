#!/usr/bin/env bash

[[ -f ${path}/${file} ]] && sudo mv ${path}/${file} ${path}/${file}.bak
echo ${input} | sudo tee -a ${path}/${file}
