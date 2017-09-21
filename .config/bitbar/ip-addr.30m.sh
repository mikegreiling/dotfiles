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
    PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com 2> /dev/null)

    echo "$PUBLIC_IP"
    echo "---"
    echo "Public IP:"
    echo "$PUBLIC_IP | color=green terminal=false bash='$0' param1=copy param2='$PUBLIC_IP'"
    echo "Local IP ($ACTIVE_ADAPTER):"
    echo "$LOCAL_IP | terminal=false bash='$0' param1=copy param2='$LOCAL_IP'"
    echo "(click to copy)"
fi
