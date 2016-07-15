{
  "fqdn": "${host}.${domain}",
   "chef_client": {
     "init_style": "none"
   },
  "chef-backend": {
    "accept_license": ${license},
    "leader": false,
    "leader_ipaddress": "${leader}",
    "secrets_file": "${secrets}"
  },
  "firewall": {
    "allow_established": true,
    "allow_ssh": true
  },
  "system": {
    "delay_network_restart": false,
    "domain_name": "${domain}",
    "manage_hostsfile": true,
    "short_hostname": "${host}"
  },
  "tags": []
}
