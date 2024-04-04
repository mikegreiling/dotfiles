#!/bin/bash

# Handle copy/paste if requested
if [ "$1" = "copy" ]; then
    # Copy the requested string to clipboard
    echo -n "$2" | pbcopy
fi

ACTIVE_ADAPTER=$(route get resolver1.opendns.com 2> /dev/null | grep "interface: " | sed "s/[^:]*: \(.*\)/\1/")

if [ -z "$ACTIVE_ADAPTER" ]
then
    echo "⚡︎ ?.?.?.?"
    echo "---"
    echo "no connection"
else
    LOCAL_IP=$(ipconfig getifaddr "$ACTIVE_ADAPTER")
    # PUBLIC_IP=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's|"||g' | xargs | cut -f1 -d" " 2> /dev/null)
    PUBLIC_IP=$(dig whoami.akamai.net. @ns1-1.akamaitech.net. +time=2 +tries=1 +short 2> /dev/null)
    if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
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
