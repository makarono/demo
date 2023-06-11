./deploy.bash -c create-backend-resources -e dev
cd infrastructure/dev
terragrunt run-all init
terragrunt run-all plan