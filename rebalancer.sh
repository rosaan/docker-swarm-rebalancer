#!/bin/bash

# Configuration via environment variables
CHECK_INTERVAL=${CHECK_INTERVAL:-60}
LOG_LEVEL=${LOG_LEVEL:-info}

log() {
    level=$1
    message=$2
    if [[ $level == $LOG_LEVEL ]]; then
        echo "[$(date +"%Y-%m-%d %T")] $level: $message"
    fi
}

redistribute_services() {
    # Get the number of active worker nodes
    active_nodes=$(docker node ls --filter "role=worker" --filter "availability=active" -q | wc -l)

    # Iterate over each service
    for service in $(docker service ls --format "{{.Name}}")
    do
        # Get the current number of replicas for the service
        current_replicas=$(docker service inspect $service --format "{{.Spec.Mode.Replicated.Replicas}}")

        # Calculate the desired number of replicas per node
        desired_replicas_per_node=$((current_replicas / active_nodes))

        # Update the service to have a total number of replicas that is evenly distributable
        docker service update --replicas $((desired_replicas_per_node * active_nodes)) $service
    done
    log "info" "Services redistributed"
}

handle_error() {
    error_message=$1
    log "error" "Error: $error_message"
}

# Main loop with error handling
while true; do
    redistribute_services || handle_error "Failed to redistribute services"
    sleep $CHECK_INTERVAL
done
