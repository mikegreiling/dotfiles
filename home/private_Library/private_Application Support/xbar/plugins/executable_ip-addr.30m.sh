#!/bin/bash

# Handle copy/paste if requested
if [ "$1" = "copy" ]; then
    # Copy the requested string to clipboard
    echo -n "$2" | pbcopy
fi

IPV4_RE='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'

# Resolve the public IP, trying the fastest method first and falling back to
# HTTPS. Many public wifi networks (captive portals, hotel/restaurant APs,
# Cisco Umbrella-style filtering) block outbound DNS to anything but a few
# well-known resolvers, which kills the direct-to-authoritative DNS trick.
# Plain HTTPS to port 443 is almost never blocked.
#
# NOTE: do NOT fall back to "dig whoami.akamai.net" via the system resolver --
# that returns the recursive resolver's egress address (e.g. a Google IP when
# 8.8.8.8 is configured), not ours.
get_public_ip() {
    local ip

    # 1. Direct DNS query to Akamai's authoritative server (~20ms when it works)
    ip=$(dig whoami.akamai.net. @ns1-1.akamaitech.net. +time=1 +tries=1 +short 2> /dev/null)
    if [[ $ip =~ $IPV4_RE ]]; then
        echo "$ip"
        return 0
    fi

    # 2. HTTPS fallbacks, in order
    local url
    for url in \
        https://api.ipify.org \
        https://checkip.amazonaws.com \
        https://icanhazip.com \
        https://ifconfig.me/ip
    do
        ip=$(curl -4 -fsS --max-time 3 "$url" 2> /dev/null | tr -d '[:space:]')
        if [[ $ip =~ $IPV4_RE ]]; then
            echo "$ip"
            return 0
        fi
    done

    return 1
}

# Use the default route rather than resolving a hostname, so adapter detection
# doesn't itself depend on DNS working.
ACTIVE_ADAPTER=$(route -n get default 2> /dev/null | awk '/interface:/ {print $2}')

if [ -z "$ACTIVE_ADAPTER" ]
then
    echo "⚡︎ ?.?.?.?"
    echo "---"
    echo "no connection"
else
    LOCAL_IP=$(ipconfig getifaddr "$ACTIVE_ADAPTER")
    PUBLIC_IP=$(get_public_ip)
    if [ -z "$PUBLIC_IP" ]
    then
        echo "⚡︎ ?.?.?.?"
        echo "---"
        echo "Public IP:"
        echo "unknown"
    else
        echo "$PUBLIC_IP"
        echo "---"
        echo "Public IP:"
        echo "$PUBLIC_IP | color=green terminal=false bash='$0' param1=copy param2='$PUBLIC_IP'"
    fi
    echo "Local IP ($ACTIVE_ADAPTER):"
    echo "$LOCAL_IP | terminal=false bash='$0' param1=copy param2='$LOCAL_IP'"
    echo "(click to copy)"
fi
