output "Resalt" {
  value = <<EOF
PhpLdapAdmin here: http://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}/ldapadmin/
use to log:
          login: cn=Manager,dc=devopsldab,dc=com
          pass: simpl_pass (if not been changed)
EOF

}
