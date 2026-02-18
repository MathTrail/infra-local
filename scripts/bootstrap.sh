#!/bin/bash
set -e
echo "MathTrail: Initializing environment..."
chezmoi init --apply --force https://github.com/MathTrail/infra-local.git
echo "Success: ~/.env.shared created with NAMESPACE=$(. ~/.env.shared; echo $NAMESPACE)"
