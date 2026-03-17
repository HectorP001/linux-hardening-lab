#!/bin/bash

# LDAP User Import Script
# Imports users from a CSV file into an OpenLDAP directory.
#
# Usage: bash import_users.sh users.csv
#
# CSV format (with header row):
#   uid,givenName,sn,uidNumber,password
#   john,John,Doe,10001,somepassword

# -------------------------------------------------------------------
# Configuration — update these to match your environment
# -------------------------------------------------------------------
LDAP_PASSWORD="your-ldap-admin-password"
BASEDN="dc=your-domain,dc=local"
ADMIN="cn=admin,dc=your-domain,dc=local"
# -------------------------------------------------------------------

CSV_FILE="$1"

if [ -z "$1" ]; then
    echo "Usage: $0 users.csv"
    exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: File $CSV_FILE not found"
    exit 1
fi

tail -n +2 "$CSV_FILE" | while IFS=, read -r uid givenName sn uidNumber password; do
    echo "Adding user: $uid"

    hashed_password=$(slappasswd -s "$password")

    ldapadd -x -D "$ADMIN" -w "$LDAP_PASSWORD" <<EOF
dn: uid=$uid,ou=users,$BASEDN
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $uid
sn: $sn
givenName: $givenName
cn: $givenName $sn
displayName: $givenName $sn
uidNumber: $uidNumber
gidNumber: $uidNumber
userPassword: $hashed_password
loginShell: /bin/bash
homeDirectory: /home/$uid
EOF

done

echo "Done! All users imported."
