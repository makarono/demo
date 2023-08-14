# n demo project
## Description
# Application Overview

This application consists of two ECS services that are exposed using an ALB (Application Load Balancer). The services are as follows:

1. **Producer Service**: This service exposes a REST API and pushes messages to a Redis queue.
2. **Consumer Service**: The consumer service retrieves messages from the Redis queue and inserts them into an RDS MySQL database.

Both services rely on the RDS MySQL database for their functionality. The consumer service inserts records into the MySQL database, while the producer service reads from the database and returns the row count and the value of the last row.

The frontend of the application is a React app that is deployed to an S3 bucket and exposed using CloudFront.

Multiple environments are defined for the application, each with its own configuration. It is important to note that the production (prod) environment should deploy a highly available (HA) infrastructure to ensure optimal performance and reliability.

The configuration for each environment is specified in Terragrunt HCL files, allowing for easy management and customization of the infrastructure.

Please note that all applications included in this project are developed by me and are primarily intended for mockup and testing purposes. It's important to understand that the code for these applications is not production-grade, as my primary focus has been on the DevOps side of work and utilizing Terraform for infrastructure provisioning.

## AWS products used
1. ecs
2. ecr
3. cloudmap service discovery
4. s3 static site serving
5. rds mysql
6. elasticache redis
7. lambda function
8. vpc
9. cloudfront
10. aws autoscaling
11. cloudwatch
12. aws secrets manager

## Prerequisites
Before running the script, ensure that you have the following packages installed:

- **bash shell**
- **git**
- **terraform**
- **aws cli**
- **terragrunt**
- **docker**
- **docker-compose or docker compose plugin**

**Configure AWS CLI with admin iam role and region**

## Table of Contents

- [Local Test](#local-test)
- [Deployment](#deployment)
- [Destroy](#destroy)
- [Notes](#notes)
- [Infrastructure](#infrastructure)
- [Backend](#backend)
- [Todo](#todo)
- [License](#license)

## Local Test
Application can be build and started localy with docker compose. To do that follow the steps:

1. navigate to app dir:

```bash
cd app/
```

```bash
rm -rf /tmp/mysql-data/ && mkdir /tmp/mysql-data/
```

```bash
docker-compose build
```

```bash
docker-compose up -d
```

```bash
docker compose logs -f --tail=20
```

**Visit localhost in your web browser to open frontend website and interact with backend**

  1. GET - get latest row and row count from mysql db
  2. POST - post current unix timestamp into mysql

**Send http request to a backend directly:**
```bash
curl -X POST -H "Content-Type: application/json" -d "{\"count\": $EPOCHSECONDS}" localhost:5080/count -v
```

```bash
curl -v localhost:5080/count
```



## Deployment
*Code is tested in eu-central-1 region, all instances types used in templates exists in that region*.

Navigate to cloned directory and start deployment script.
This script will configure your AWS profile, prompt you for necessary inputs, and save the configuration details.


Enter the AWS_PROFILE when prompted. Make sure the provided profile exists in your AWS CLI configuration.
Enter the AWS_DEFAULT_REGION when prompted. This specifies the AWS region to deploy resources.
Enter the ENV when prompted. Specify the environment you want to deploy (e.g., test, dev, stage, prod).

The test, dev, and stage environments share similar configurations, while the prod environment deploys a highly available (HA) infrastructure. It is strongly recommended to  use the deployment of the prod environment.

1. Clone the repository:
```bash
$ git clone <repository_url>
$ cd <repository_directory>
```

2. Start the deployment script:
```bash
$ cd <cloned_dir>
$ bash ./deploy.sh
```

3. Wait ecs services to become healty and registered to alb . Navigate to cloudfront endpoint and use the frontend. <span style="color:red;"> Since ALB entpoint listens for http requests, web browser will block unsecure mixed content . Be sure to allow insecure content in browser:</span>
Google chrome enable mixed content: https://experienceleague.adobe.com/docs/target/using/experiences/vec/troubleshoot-composer/mixed-content.html?lang=en

*If deployment fails rerun script again!*

## Destroy

```bash
cd terraform/infrastructure/<ENV>
```

```bash
export AWS_DEFAULT_REGION=<region> AWS_PROFILE=<aws_profile>
```

```bash
terragrunt run-all destroy
```

```bash
aws ecr delete-repository --repository-name producer --force ; aws ecr delete-repository --repository-name consumer-go --force
```

**Use this dangerous step only if there is no critical resources to delete**
```bash
AWS_PROFILE=$AWS_PROFILE cloud-nuke aws --region $AWS_DEFAULT_REGION
```

# Notes

1. Redis is deployed as a serverless elastic cache in a multi-AZ configuration.
2. Enviroments test, dev, stage are realy similar in configuration . Prod env deploys HA infrastructure. I suggest you to deploy prod env
2. Route53 and a certificate for CloudFront were not used because I don't have a domain that could be used for it. Before deployment, you should transfer your own domain to Route53.
3. I utilized a security group module that is reliable and efficient, considering the time constraints I had at the moment.
4. CloudFront calls the HTTP API of the S3 website. However, modern browsers block such insecure communication by default. Here are instructions on how to enable mixed content in Google Chrome for testing purposes: [Enable Mixed Content in Google Chrome](https://experienceleague.adobe.com/docs/target/using/experiences/vec/troubleshoot-composer/mixed-content.html?lang=en).
5. It is crucial to never expose secrets in environment variables, as I did in the ECS services and MySQL Lambdas. Instead, secrets should be fetched from AWS Secrets Manager.


# Infrastructure
The infrastructure for this project consists of various components that work together to serve the application. Here is a breakdown of the different elements:

**Frontend:** The frontend of the application is served from an S3 bucket. The bucket is configured to allow access only from the CloudFront distribution associated with it. CloudFront acts as a content delivery network (CDN) and points to the S3 bucket. The CloudFront distribution has a default AWS TLS certificate for secure communication.

**Backend (REST API) producer service:** The backend is a REST API service running on Fargate ECS (Elastic Container Service). The service is exposed through an Application Load Balancer (ALB). The ALB endpoint is used by the frontend to interact with the backend. When a request reaches the ECS producer service, it pushes the message into a Redis queue.

**Consumer Service:** The consumer service runs as a Fargate ECS service and listens to the Redis queue. It pulls messages from the queue and inserts them into a MySQL database.

**Redis Cluster:** The Redis cluster is deployed as a scalable and serverless Elasticache solution. It provides the infrastructure for the Redis queue used by the backend services.

**MySQL Database:** The MySQL database is hosted in RDS (Relational Database Service).

**VPC and Subnets:** The infrastructure is deployed within a VPC (Virtual Private Cloud) and consists of two private subnets and two public subnets. The VPC is configured with internet gateways, route tables, and other default AWS settings following best practices. It would be better to deploy into 3 subnets but due to costs its only deployed into two.

**Security Groups:** Security groups are used to control access to different resources. They allow access to the MySQL, Redis, ECS, and Lambda services, ensuring secure communication within the infrastructure.

**MySQL Import Lambda:** A Lambda function is utilized to import MySQL dump and tables into the MySQL database. Since MySQL is running in private subnets and not directly accessible from the internet, this Lambda function serves as an intermediary for importing data.

**Private DNS Namespace:** ECS services can discover each other using CloudMap private DNS namespace, enabling easy communication and service discovery within the infrastructure.

Overall, the infrastructure is designed to provide secure and scalable application deployment. The frontend is publicly accessible via the S3 bucket and CloudFront, while the backend services and databases are deployed in private subnets for enhanced security.



# Backend

## Producer
The API consists of the following endpoints:

1. `/` - This is a default endpoint that returns an empty response with a status code of 200. It is primarily used for testing purposes.

2. `/health` - This endpoint is used to check the health status of the application. It returns a JSON response with a status message indicating that the application is running without issues. The response also includes the hostname of the host where the ECS container is running.

3. `/count` - This endpoint supports both GET and POST methods. When a POST request is made to this endpoint, it expects a JSON payload containing a "count" value. The API then connects to Redis and pushes the count value to a specified Redis queue. On a successful push, it returns a JSON response indicating that the value has been added to the Redis queue.

    When a GET request is made to this endpoint, the API connects to MySQL and retrieves the overall count of records from a specific table. It also fetches the latest count value from the same table. The API returns a JSON response containing the overall count, the latest count value, and the hostname of the ECS container where the API is running.

The API utilizes environment variables to configure settings:

- Redis configuration: It reads the Redis host, port, and cluster information from environment variables. If the cluster mode is enabled, it connects to a Redis cluster; otherwise, it connects to a standalone Redis instance.

- HTTP port: The API listens on the specified HTTP port, which is read from an environment variable.

- Redis queue: The name of the Redis queue is read from an environment variable.

- MySQL configuration: The API reads the MySQL database connection details, such as host, port, user, password, and database name, from environment variables.

The application also includes additional functionality:

- Connection to Redis: It provides a function to establish a connection to Redis, either to a standalone instance or a Redis cluster, based on the configuration.

- Retry mechanism: It includes a retry function for pushing values to Redis. If there is a failure in pushing the value to the queue, it retries the operation with a specified number of attempts and a delay between retries.

- MySQL connection: It establishes a connection to the MySQL database with error handling and retry logic.

- CORS headers: It adds Cross-Origin Resource Sharing (CORS) headers to the responses, allowing requests from any origin.

The API is designed to be run as a Flask application and can be executed by running the script. It listens on all available network interfaces (`0.0.0.0`) and the specified HTTP port.

The application described in the Dockerfile runs the Envoy proxy as a sidecar alongside the Flask application within the same container. This architecture is commonly used in microservices-based applications and brings several benefits.

## Consumer-go
This Go code snippet represents a program that consumes count values from a Redis queue and inserts them into a MySQL database.

1. The code imports necessary packages, including the Redis and MySQL drivers, and the required context and database/sql packages.

2. In the `main` function, it retrieves environment variables to configure the Redis and MySQL connections. If the environment variables are not set, default values are used.

3. It creates a Redis client using the obtained Redis host, port, and queue information.

4. The context is initialized for the Redis operations.

5. It retrieves the environment variables for the MySQL connection configuration, such as host, port, user, password, and database name.

6. It establishes a connection to the MySQL database using the obtained connection parameters.

7. A loop is initiated to continuously consume count values from the Redis queue.

8. Inside the loop, the program calls `BLPop` on the Redis client to block and wait for an item to be pushed to the specified queue. When an item is received, it extracts the count value.

9. The count value is then inserted into the MySQL database using an SQL query.

10. If any errors occur during the Redis or MySQL operations, appropriate error messages are displayed.

11. After each iteration, the program sleeps for 5 seconds before attempting to consume the next count value.

This code demonstrates a consumer that retrieves count values from a Redis queue and persists them in a MySQL database. The program continuously runs, ensuring that new count values are consumed and inserted into the database as they become available.



# Todo
Here is the revised list with correct numbering:

1. Build Docker images with appropriate tags for each environment.
2. Create a non-administrator RDS MySQL user and utilize it in ECS and Lambda.
3. Due to time constraints, a comprehensive security group module was not implemented. However, the chosen module is highly effective.
4. Add Redis username and password for enhanced security, either through IAM or auth token.
5. Make Terraform modules more DRY (Don't Repeat Yourself) to improve code reusability.
6. Configure Redis auto scaling to dynamically adjust resources based on demand.
7. Configure CloudWatch alarms for Redis and RDS MySQL to monitor performance and resource utilization.
8. Add health checks to Docker images to ensure the availability and proper functioning of containers.
9. Include Route53 hosted zone configuration and generate ACM (AWS Certificate Manager) certificates for the frontend and API. Attach these certificates to ALB (Application Load Balancer) and CloudFront for secure communication.
10. It is recommended to deploy the application in the `eu-central-1` region due to the specific instance availability of Redis and MySQL RDS, which are not accessible in `eu-north-1`.
11. Strengthen the ECS service policy by restricting access to specific MySQL ARNs and Redis ARNs with precise policy actions.
12. Configure a custom health check for the ALB target group based on the specific requirements of the services.
13. Applications running within containers should not operate under the root user for security reasons.
14. Avoid passing MySQL username and password as environment variables in the ECS service, as this poses a security risk. Secure credential retrieval must implemented in aapplications itself and fetched from aws secrets manager.
15. Consolidate Docker Compose configurations into YAML anchors to improve code organization and maintainability.
16. Deploy all components in three availability zones (AZs) for enhanced redundancy and fault tolerance.


## License
GNU General Public License v3.0 [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)
