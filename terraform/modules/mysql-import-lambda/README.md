```bash
base=$(base64 -w0 ../../../app/mysql/dump.sql)

# Your printf template string
template='{ "base64": "%s" }'

# Variable to store your rendered template JSON string
data=""


# Render the template, substituting the variable values and save the result into $data
printf -v data "$template" "$base"

# Print it out
#echo "$data"

aws lambda invoke --function-name mysql-import --cli-binary-format raw-in-base64-out --payload "${data}" /dev/stdout
```