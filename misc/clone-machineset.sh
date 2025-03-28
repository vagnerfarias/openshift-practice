#!/bin/bash

set -euo pipefail

# Print usage if no arguments are passed
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <existing-ms-name> <new-ms-name> <instance-type> [replicas] [--output <file>]" >&2
  exit 1
fi

# Defaults
OUTPUT_FILE=""
POSITIONAL_ARGS=()

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -*)
      echo "❌ Unknown option: $1" >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Restore positional arguments safely
set -- "${POSITIONAL_ARGS[@]:-}"

# Usage check
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <existing-ms-name> <new-ms-name> <instance-type> [replicas] [--output <file>]" >&2
  exit 1
fi

EXISTING_NAME="$1"
NEW_NAME="$2"
INSTANCE_TYPE="$3"
REPLICAS="${4:-1}"
NAMESPACE="openshift-machine-api"

# Function to fetch and modify MachineSet
generate_yaml() {
  kubectl get machineset "$EXISTING_NAME" -n "$NAMESPACE" -o yaml |
  yq eval "
    del(
      .metadata.uid,
      .metadata.resourceVersion,
      .metadata.selfLink,
      .metadata.creationTimestamp,
      .metadata.generation,
      .metadata.managedFields,
      .status
    ) |
    .metadata.name = \"$NEW_NAME\" |
    .spec.replicas = $REPLICAS |
    .spec.template.spec.providerSpec.value.instanceType = \"$INSTANCE_TYPE\"
  " -
}

# Output result
if [[ -n "$OUTPUT_FILE" ]]; then
  generate_yaml > "$OUTPUT_FILE"
  echo "✅ New MachineSet written to $OUTPUT_FILE"
else
  generate_yaml
fi
