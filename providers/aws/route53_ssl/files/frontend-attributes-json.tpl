{
  "fqdn": "${host}.${domain}",
   "chef_client": {
     "init_style": "none"
   },
  "system": {
    "delay_network_restart": false,
    "domain_name": "${domain}",
    "manage_hostsfile": true,
    "short_hostname": "${host}"
  },
  "tags": []
}
