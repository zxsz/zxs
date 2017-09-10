#!/bin/bash
#
df | awk '/\/dev\/sd/{if(+$5>80)print $1,"will be full used:",$5}'
