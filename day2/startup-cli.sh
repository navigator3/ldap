sudo systemctl stop firewalld
sudo systemctl disable firewalld
echo "${name}_${surname}"
mkdir -p /tmp/scripts
echo "${ip_ldap_serv} \
privet" > /tmp/scripts/test_ip
sudo yum -y install openldap-clients nss-pam-ldapd
#cat > /tmp/scripts/
#ldapserver=(LDAP server's hostname or IP address)
#ldapbasedn="dc=(your own domain name)“


authconfig --enableldap \
--enableldapauth \
--ldapserver=${ip_ldap_serv} \
--ldapbasedn="dc=devopsldab,dc=com" \
--enablemkhomedir \
--updateall
 #authconfig --enableldap --enableldapauth --ldapserver=ldap-terraform --ldapbasedn="dc=devopsldab,dc=com" --enablemkhomedir --update
#getent passwd


sudo cat<<EOF| sudo tee /opt/ssh_ldap.sh
#! /bin/bash
/usr/bin/ldapsearch -x '(&(objectClass=posixAccount)(uid='"\$1"'))' 'sshPublicKey' | sed -n '/^ /{H;d};/sshPublicKey:/x;\$g;s/\n *//g;s/sshPublicKey: //gp'
EOF


chmod +x /opt/ssh_ldap.sh
sudo sed -i '51c AuthorizedKeysCommand /opt/ssh_ldap.sh' /etc/ssh/sshd_config
sudo sed -i '52c AuthorizedKeysCommandUser nobody' /etc/ssh/sshd_config
sudo sed -i '65c PasswordAuthentication yes' /etc/ssh/sshd_config

sudo systemctl stop sshd
sudo systemctl start sshd
