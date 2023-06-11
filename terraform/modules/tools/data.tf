#data "http" "external_ip" {
#  url = "https://api.ipify.org?format=json"
#}
#
#
#
#output "current_ip_address" {
#  value = jsondecode(data.http.external_ip.response_body)["ip"]
#}
#
#output "current_ip_address_cidr" {
#  value = format("%s/32", jsondecode(data.http.external_ip.response_body)["ip"])
#}


data "http" "external_ip" {
  url = "http://checkip.amazonaws.com"
  request_headers = {
    "Content-Type" = "text/plain"
  }
}

output "current_ip_address" {
  value = replace(data.http.external_ip.response_body, "\n", "")
}

output "current_ip_address_cidr" {
  value = replace(data.http.external_ip.response_body, "\n", "/32")
}

data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

