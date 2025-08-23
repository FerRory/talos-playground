# Storage account to use
export STORAGE_ACCOUNT="talosimagestorage"

# Storage container to upload to
export STORAGE_CONTAINER="images"

# Resource group name
export GROUP="talos"

# Location
export LOCATION="westeurope"

# Get storage account connection string based on info above
export CONNECTION=$(az storage account show-connection-string \
                    -n $STORAGE_ACCOUNT \
                    -g $GROUP \
                    -o tsv)
