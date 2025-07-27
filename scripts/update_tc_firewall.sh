#!/bin/sh
# Convert Tencent cloud firewallrules json output to a new json input file to modify rules.
# Replace v6 source CidrBlock to home address.
INS="$1"
V6CIDR="$2"
[ -z "${V6CIDR}" ] && echo "Syntax: $0 InstanceId V6CIDR" && exit 0
if ! command -v tccli >/dev/null; then echo "Error: tccli not found!"; exit 1;fi
#
tccli lighthouse DescribeFirewallRules --InstanceId ${INS} \
|jq '.|del(.FirewallRuleSet[].Ipv6CidrBlock|select(.==""))' \
|jq '.|del(.FirewallRuleSet[].CidrBlock|select(.==""))' \
|jq '.|del(.TotalCount,.RequestId)' \
|jq ".InstanceId=\"${INS}\""  \
|jq '.+{FirewallRules:.FirewallRuleSet} | del (.FirewallRuleSet)' \
|jq ".FirewallRules|=map(if .FirewallRuleDescription==\"bore-v6\" then .Ipv6CidrBlock= \"${V6CIDR}\" else . end)" \
|jq ".FirewallRules|=map(if .Protocol==\"ICMPv6\" then .Ipv6CidrBlock= \"${V6CIDR}\" else . end)"

# > /tmp/$$
# if tccli lighthouse ModifyFirewallRules --cli-input-json file:///tmp/$$; then rm /tmp/$$; fi
