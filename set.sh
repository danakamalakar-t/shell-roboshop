#!/bin/bash

set -euo pipefail

error_handler() {
    echo "❌ Error occurred!"
    echo "Line: $1"
    echo "Command: $2"
}

trap 'error_handler $LINENO "$BASH_COMMAND"' ERR