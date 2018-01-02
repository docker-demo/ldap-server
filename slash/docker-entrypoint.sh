#!/usr/bin/env ash
#
# This script bootstraps an OpenLDAP environment with example users, using either
# a supplied or randomly generated password.

set -e

# Set static variable and create readonly user by default
CONF_FILE=/etc/openldap/slapd.conf
LDIF_FILE=/etc/openldap/slapd.ldif

# Check if it is already bootstrapped, otherwise it will replace the password on restart.
if [ ! -f /var/run/openldap.bootstrapped ]; then
    if [ ! ${LDAP_ROOTDN_PASSWORD} ] || [ ${LDAP_ROOTDN_PASSWORD} = "" ]; then

        # If no password supplied then generate a random one of 14 characters and apply to all users.
        RANDOM_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c14)

        # Set all users to the same password
        export LDAP_ROOTDN_PASSWORD=${RANDOM_PASSWORD}

        # Encrypt random password as md5crpyt and escape special characters for sed
        ENCRYPTED_PASSWORD=$(/usr/sbin/slappasswd -s ${RANDOM_PASSWORD} | sed -e 's/[()&\/!%$*#@^+.]/\\&/g')
        sed -i "s|{{ ROOTDN PASSWORD }}|${ENCRYPTED_PASSWORD}|" ${CONF_FILE}
        sed -i "s|{{ ROOTDN PASSWORD }}|${ENCRYPTED_PASSWORD}|" ${LDIF_FILE}
        echo "#################################################"
        echo "The password for all users is: ${RANDOM_PASSWORD}"
        echo "#################################################"
    else
        if [ ${#LDAP_ROOTDN_PASSWORD} -lt 8 ]; then
            echo "ERROR: Password length is too short. Please enter a longer password with a minimum of 8 characters."
            exit 1
        fi

        # Encrypt supplied password as md5crpyt and escape special characters for sed
        ENCRYPTED_PASSWORD=$(/usr/sbin/slappasswd -s ${LDAP_ROOTDN_PASSWORD} | sed -e 's/[()&\/!%$*#@^+.]/\\&/g')
        sed -i "s|{{ ROOTDN PASSWORD }}|${ENCRYPTED_PASSWORD}|" ${CONF_FILE}
        sed -i "s|{{ ROOTDN PASSWORD }}|${ENCRYPTED_PASSWORD}|" ${LDIF_FILE}
        echo "#################################################"
        echo "The password for all users is: ${LDAP_ROOTDN_PASSWORD}"
        echo "#################################################"
    fi
    # Set to bootstrapped, preventing overwriting the password with each start-up
    touch /var/run/openldap.bootstrapped
else
    echo "OpenLDAP already bootstrapped, proceeding..."
fi

for f in $(find /etc/openldap/ldif -mindepth 1 -maxdepth 1 -type f -name \*.ldif  | sort); do
    echo "Processing file ${f}"
    /usr/sbin/slapadd -l ${f}
done

chown -R ldap:ldap /var/lib/openldap/openldap-data

# Still enable debug mode through an environment variable
slapd -d ${LDAP_LOG_LEVEL:-32768} -u ldap -g ldap

exec "$@"
