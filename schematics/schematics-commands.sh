
# Export the terraform state to a json file
export WORKSPACE_ID="eu-de.workspace.roks-rhoai-da.6f121f7a"
ibmcloud sch state list --id $WORKSPACE_ID -o json > tfstate.json

# Delete a resource from the state (Delete the resource in the console first!)
ibmcloud sch workspace state rm --i $WORKSPACE_ID  --address "ibm_logs_router_tenant.logs_router_tenant_instance_de"

# Get logs for a job
ibmcloud sch job logs --id 762620939f475ee3cb3bd1587d9a685c