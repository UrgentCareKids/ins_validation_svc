# #!/bin/bash 

# >&2 echo "Flyway Info: Seeding with data"

# base_data=`ls /seed/base-data/*sql`

# write_pg() {
#     arr=$1
#     for filename in "${arr[@]}"
#     do
#         PGPASSWORD=$POSTGRES_PASSWORD  psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "dev-ins-validation-svc" < ${filename}
#     done
# }

# write_pg $base_data
