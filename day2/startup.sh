#!/bin/bash
sudo mkdir -p /tmp/startup
echo "privet from ${name} ${surname}" > ~/testHomeDir
sudo systemctl stop firewalld
sudo systemctl disable firewalld
echo "1" > /tmp/startup/steps
sudo yum install -y openldap openldap-servers openldap-clients
echo "2" >> /tmp/startup/steps
sudo systemctl start slapd
sudo systemctl enable slapd
sudo systemctl status slapd
echo "3" >> /tmp/startup/steps
# firewall-cmd --add-service=ldap (if uses)
#PASS=$(slappasswd -s your_password)
echo "${your_password}" > /tmp/startup/realpasswd
echo "$(slappasswd -s ${your_password})" > /tmp/startup/hesh
hesh=$(cat /tmp/startup/hesh)
passwd=$(cat /tmp/startup/realpasswd)
echo "4" >> /tmp/startup/steps
mkdir -p /tmp/startup/${name}/${surname}
touch /tmp/startup/ldaprootpasswd.ldif

sudo cat > /tmp/startup/ldaprootpasswd.ldif << EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $hesh
EOF


echo "5" >> /tmp/startup/steps
#sudo sed -e "s/PASSWORD/$hesh/g" -i /tmp/startup/ldaprootpasswd.ldif
echo "6" >> /tmp/startup/steps
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/startup/ldaprootpasswd.ldif
echo "7" >> /tmp/startup/steps
sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif


sudo cat > /tmp/startup/ldapdsshpubkey.ldif << EOF
dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: ( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey'
    DESC 'MANDATORY: OpenSSH Public key'
    EQUALITY octetStringMatch
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
olcObjectClasses: ( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' SUP top AUXILIARY
    DESC 'MANDATORY: OpenSSH LPK objectclass'
    MAY ( sshPublicKey $ uid )
    )
EOF

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/startup/ldapdsshpubkey.ldif



sudo cat > /tmp/startup/ldapdomain.ldif << EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=devopsldab,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=devopsldab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=devopsldab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $hesh

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=devopsldab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=devopsldab,dc=com" write by * read
EOF
#sudo sed -e "s/PASSWORD/$hesh/g" -i /tmp/startup/ldapdomain.ldif
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/startup/ldapdomain.ldif




sudo cat > /tmp/startup/baseldapdomain.ldif << EOF
dn: dc=devopsldab,dc=com
objectClass: top
objectClass: dcObject
objectclass: organization
o: devopsldab com
dc: devopsldab

dn: cn=Manager,dc=devopsldab,dc=com
objectClass: organizationalRole
cn: Manager
description: Directory Manager

dn: ou=People,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: Group
EOF


q1="sudo ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w $passwd -f /tmp/startup/baseldapdomain.ldif"
echo q1 > /tmp/startup/script
$q1

#>>>>>>> create Group
sudo cat > /tmp/startup/ldapgroup.ldif << EOF
dn: cn=Manager,ou=Group,dc=devopsldab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOF

q2="sudo ldapadd -x  -D "cn=Manager,dc=devopsldab,dc=com" -w $passwd -f /tmp/startup/ldapgroup.ldif"
echo q2 >> /tmp/startup/script
$q2



sudo cat > /tmp/startup/ldapuser.ldif << EOF
dn: cn=test,ou=People,dc=devopsldab,dc=com
cn: test
gidnumber: 1005
givenname: test
homedirectory: /home/users/test
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
objectclass: ldapPublicKey
sn: test
sshPublicKey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpVhag3LxHKXpqp44nWHSxZUNpZJf0Mmog9bpppYsl1C+cdpBo8pKXzuVXCR3Xnv//wB6nn40hoVnA+0/rVqMf+eblR6fJ25CpBFSen0fuizUJyf+eM5uBRORteTQbF0ChPyMohKLLt7griuvFj2/weii50uadiXgAJ58QZUeBKHHwAtJfHp/9wFXxsOj8b86Y+cz4SyFAKaMinHEvoLkN9uhwZxNvFIhV5TMCwspa2YJvjmPHBx5DUPJBV7BSnczjWQbYni1iwFpoYF6T25y5VCf1P/mpA6c8E4O36aiT2nQ0pDHzVSNQGo/SapQAJQ0UhVaGi6Lpmsedxu1Ic7Bh root@localhost.localdomain
uid: test
uidnumber: 1010
userpassword: $hesh
EOF

#sudo sed -e "s/PASSWORD/$hesh/g" -i /tmp/startup/ldapuser.ldif
q3="sudo ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w $passwd -f  /tmp/startup/ldapuser.ldif"
echo q3 >> /tmp/startup/script
$q3


sudo yum -y install epel-release
sudo yum --enablerepo=epel -y install phpldapadmin
sudo sed "s/.*servers->setValue('login','attr','dn').*/\$servers->setValue('login','attr','dn')/" -i /etc/phpldapadmin/config.php
sudo sed "s/.*servers->setValue('login','attr','uid').*/\/\/\$servers->setValue('login','attr','uid')/" -i /etc/phpldapadmin/config.php
sudo sed '12i\Require all granted' -i /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd
#sudo rm -fr /tmp/startup/
