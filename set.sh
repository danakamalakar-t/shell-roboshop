#!/bin/bash

set -euo pipefail

error_handler() {
    echo "❌ Error occurred!"
    echo "Line: $1"
    echo "Command: $2"
    echo "Exiting with status: $?"
    exit 1
}

trap 'error_handler $LINENO "$BASH_COMMAND"' ERR