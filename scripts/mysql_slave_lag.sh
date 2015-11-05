#!/bin/bash


mysql_status=$(mysql -s -e 'show slave status\G')
seconds=$(echo "$mysql_status" | grep Seconds_Behind_Master | awk {'print $2'})
running=$(echo "$mysql_status" | grep Slave_SQL_Running | awk {'print $2'})

if [ "$running" = "No" ]; then
  echo "MySQL slave is not running"
  echo "Seconds_Behind_Master: $seconds"
  exit 1
fi

test "$seconds" = "0"
retval=$?
echo "Seconds_Behind_Master: $seconds"
exit $retval
