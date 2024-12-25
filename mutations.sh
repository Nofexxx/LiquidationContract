#!/bin/bash
# run-vertigo.sh

# Create output directory if it doesn't exist
mkdir -p mutations_results

# Parse command line arguments
DETACHED_FLAG=""
while getopts "d" opt; do
  case $opt in
    d) DETACHED_FLAG="-d" ;;
  esac
done

# Build and run with correct volume mount path
docker build -t vertigo .
docker run --platform linux/amd64 ${DETACHED_FLAG} \
    -v "$(pwd)/mutations_results:/mutations/output" \
    vertigo

# Remove the image after running
# docker stop $(docker ps -q)
# docker rmi vertigo

echo "Results will be saved to mutations_results"
