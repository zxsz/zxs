#!/bin/bash
#
DEV_LIST=`df | sed -r '/^\/dev\/[sh]d/!d;s@(^/dev/[sh]d[a-z][0-9]{1,}).*([0-9]{2,3})%.*@\1:\2@'`
for i in $DEV_LIST;do
    [ ${i#*:} -ge 8 ] &&  wall "Warnning  $i% will full"
done


