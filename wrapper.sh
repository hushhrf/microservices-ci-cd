#!/bin/sh
cat <<EOF > /tmp/run_restore.sh
curl -s -X POST http://localhost:8080/jenkins/scriptText --data-urlencode "script=\$(cat /tmp/restore.groovy)"
EOF
sh /tmp/run_restore.sh
