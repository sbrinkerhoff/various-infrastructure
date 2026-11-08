#!/usr/bin/env bash
# Retry `terraform apply` across Ashburn's availability domains and A1 sizes until capacity frees up.
# Each round tries every size (largest first) in every AD, so it lands the biggest size available.
# Stops on success or on any error other than capacity / rate limiting / network blips.
# On success, writes the winning AD and size to instance.auto.tfvars so later applies keep them.
#   ./retry-apply.sh                       # default: wait 300s between rounds
#   INTERVAL=60 ./retry-apply.sh
#   SIZES="2:12 1:6" ./retry-apply.sh      # OCPU:GB pairs, tried in order
set -u
cd "$(dirname "$0")"

INTERVAL="${INTERVAL:-300}"
SIZES="${SIZES:-4:24 2:12 1:6}"
LOG="retry-apply.log"
round=0

while true; do
  round=$((round + 1))
  for size in $SIZES; do
    ocpus="${size%%:*}"
    mem="${size##*:}"
    for ad in 1 2 3; do
      tag="round $round ${ocpus}/${mem}GB AD-$ad"
      echo "$(date '+%F %T') $tag: applying" | tee -a "$LOG"
      out=$(terraform apply -auto-approve -input=false -no-color \
        -var "availability_domain_number=$ad" -var "ocpus=$ocpus" -var "memory_in_gbs=$mem" 2>&1)
      if [ $? -eq 0 ]; then
        printf 'availability_domain_number = %s\nocpus = %s\nmemory_in_gbs = %s\n' "$ad" "$ocpus" "$mem" > instance.auto.tfvars
        echo "$out" | tail -8 | tee -a "$LOG"
        echo "$(date '+%F %T') SUCCESS: $tag" | tee -a "$LOG"
        exit 0
      fi
      if echo "$out" | grep -qE 'Out of host capacity|TooManyRequests|429'; then
        echo "$(date '+%F %T') $tag: no capacity" | tee -a "$LOG"
        sleep 5
      elif echo "$out" | grep -qE 'no such host|i/o timeout|operation timed out|connection reset|connection refused|network is unreachable|TLS handshake timeout|allowed clock skew'; then
        echo "$(date '+%F %T') $tag: network error, will retry" | tee -a "$LOG"
        sleep 30
      else
        echo "$out" | grep -A3 'Error:' | tee -a "$LOG"
        echo "$(date '+%F %T') FAILED with unexpected error; stopping" | tee -a "$LOG"
        exit 1
      fi
    done
  done
  sleep "$INTERVAL"
done
