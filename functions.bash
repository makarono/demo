# Function to print a message with formatting
log() {
  local message="$1"
  local line=""

  # Calculate the length of the message
  local message_length=${#message}

  # Build the separator line based on the message length
  for ((i = 0; i < message_length; i++)); do
    line+="="
  done

  #echo "$line"
  #uppercase first letter of a message
  echo "${message^}"
  echo "$line"
}

check-docker() {
  # Check if Docker is installed
  if ! command -v docker &>/dev/null; then
    log "Docker is not installed. Please install Docker." >&2
    exit 1
  fi

  # Check if Docker is running
  if ! docker info &>/dev/null; then
    log "Docker is not running. Please start Docker service." >&2
    exit 1
  fi

  log "Docker is installed and running."
}

check-docker-compose() {
  if ! command -v docker-compose >/dev/null 2>&1; then
    log "docker-compose is not installed. Trying alternative command..."
    if docker compose -h >/dev/null 2>&1; then
      log "Alternative command 'docker compose' plugin is available."
    else
      log "Alternative command 'docker compose' is not available either. Please install docker-compose."
      exit 1
    fi
  fi
}

build-docker-images() {
  set-docker-compose
  local PLATFORM=${1}

  PLATFORM=${PLATFORM} \
    AWS_ACCOUNT=${AWS_ACCOUNT} \
    AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
    ${DC} -f $(pwd)/app/docker-compose.yaml build --build-arg env=${ENV} --progress=plain
}

docker-login() {
  set -x
  aws ecr get-login-password --profile ${AWS_PROFILE} | docker login -u AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
  set +x
}

function docker-push() {
  images=("$@")
  for img in "${images[@]}"; do
    PLATFORM="linux/amd64" docker-compose -f $(pwd)/app/docker-compose.yaml push "${img}"
  done
}

function create-backend-resources() {
  local BUCK="tfstate-filesx-${AWS_ACCOUNT}-${AWS_DEFAULT_REGION}"

  # Check if S3 bucket already exists
  if ! aws s3api head-bucket --bucket ${BUCK} --region "${AWS_DEFAULT_REGION}" >/dev/null 2>&1; then
    log "Creating Terraform state S3 bucket: ${BUCK}"
    aws s3api create-bucket --bucket ${BUCK} --region "${AWS_DEFAULT_REGION}" --create-bucket-configuration LocationConstraint="${AWS_DEFAULT_REGION}"
    aws s3api put-bucket-versioning --bucket ${BUCK} --versioning-configuration Status=Enabled
  else
    log "Terraform state S3 bucket '${BUCK}' already exists. Skipping creation."
  fi

  # Check if DynamoDB table already exists
  if ! aws dynamodb describe-table --table-name terraform-state-lock-dynamo --profile ${AWS_PROFILE} >/dev/null 2>&1; then
    log "Creating Terraform state lock DynamoDB table"
    aws dynamodb create-table \
      --table-name terraform-state-lock-dynamo \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=3,WriteCapacityUnits=3 \
      --profile ${AWS_PROFILE}
  else
    log "Terraform state lock DynamoDB table 'terraform-state-lock-dynamo' already exists. Skipping creation."
  fi
}

# check aws supported environments
check-env() {
  if [ "${ENV}" = "dev" ]; then
    log "Deploy to: ${ENV}"
  elif [ "${ENV}" = "test" ]; then
    log "Deploy to: ${ENV}"
  elif [ "${ENV}" = "stage" ]; then
    log "Deploy to: ${ENV}"
  elif [ "${ENV}" = "prod" ]; then
    log "Deploy to: ${ENV}"
  else
    log "Unsuported environment: ${ENV}. Supported envs are: [ test, dev, stage ]" && exit 1
  fi
}

# Define the function to install GNU sed using Homebrew on macOS
install-gnused() {
  # Check if the OS or platform is Mac
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Check if gnused is already installed
    if ! command -v gsed >/dev/null 2>&1; then
      # Install gnused using Homebrew
      brew install gsed
      s=$(which gsed)
      alias sed=${s}
    fi
  fi
}

# Define the function to replace a line in a file
replace-line() {
  local replacement_var="$1"
  local var_to_replace="$2"
  local filename="$3"

  # Use sed to replace the entire line that contains the variable to replace with the replacement variable
  sed -i "/$var_to_replace/c $replacement_var" "$filename"
}

replace-first-match-line() {
  local replacement_var="$1"
  local var_to_replace="$2"
  local filename="$3"

  # replace first match whole line
  sed -i "0,/$(echo $var_to_replace)/c $(echo $replacement_var)" "$filename"
}

#set docker compose command
set-docker-compose() {
  DC="docker-compose"
  if ! command -v ${DC} >/dev/null 2>&1; then
    if docker compose -h >/dev/null 2>&1; then
      DC="docker compose"
    fi
  fi
  echo ${DC}
}

function stop-and-delete-container() {

  local CNT_NAME=${1}
  if [ "$(docker ps -a -q -f name=$CNT_NAME)" ]; then
    docker stop $CNT_NAME
    docker rm $CNT_NAME
    log "Container: $CNT_NAME stopped and deleted"
  fi
}

# gets built frontend code from docker container and copy it to local path
function get-frontend-code() {
  # stop frontend container if its started during local testing
  stop-and-delete-container "frontend"
  P="/tmp/tmp-frontend-${ENV}"
  [ -d ${P} ] && (rm -rf ${P} && mkdir -p ${P})
  export PLATFORM="linux/amd64"
  ${DC} -f $(pwd)/app/docker-compose.yaml up -d frontend
  docker cp frontend:/usr/share/nginx/html/. ${P}
  unset PLATFORM
}
