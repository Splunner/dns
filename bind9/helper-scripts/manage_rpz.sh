#!/bin/bash
# Script to manage blocked domains in a BIND9 RPZ (Response Policy Zone) file
# Author: Patryk Michn /Splunner
#
# Usage examples:
#   ./manage_rpz.sh add example.com -f /etc/bind/rpz.local.conf
#   ./manage_rpz.sh remove example.com -f /etc/bind/rpz.local.conf
#   ./manage_rpz.sh list -f /etc/bind/rpz.local.conf

# example Usage
#  bash manage_rpz.sh list -f ../bind9-recursive-config/zones/rpz.local.conf 
#  bash manage_rpz.sh add test.com -f ../bind9-recursive-config/zones/rpz.local.conf 
#  bash manage_rpz.sh add tes23.com -f ../bind9-recursive-config/zones/rpz.local.conf 
#  bash manage_rpz.sh list -f ../bind9-recursive-config/zones/rpz.local.conf

# Default RPZ file (can be overridden using -f)
DEFAULT_RPZ_FILE="/etc/bind/rpz.local.conf"

# ===== Parse arguments =====
ACTION=""
DOMAIN=""
RPZ_FILE="$DEFAULT_RPZ_FILE"

while [[ $# -gt 0 ]]; do
    case "$1" in
        add|remove|list)
            ACTION="$1"
            shift
            ;;
        -f)
            RPZ_FILE="$2"
            shift 2
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
                shift
            else
                echo "❌ Unknown argument: $1"
                exit 1
            fi
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    echo "Usage: $0 {add|remove|list} [domain] [-f path_to_file]"
    exit 1
fi

# ===== Functions =====

init_file() {
    if [ ! -f "$RPZ_FILE" ]; then
        cat <<EOF > "$RPZ_FILE"
\$TTL 2h
@   IN  SOA localhost. root.localhost. (1 1h 15m 30d 2h)
    IN  NS  localhost.

# Blocked domains:
EOF
        echo "🆕 Created new RPZ file: $RPZ_FILE"
    fi
}

add_domain() {
    local domain="$1"
    if grep -qE "^${domain}\.\s+CNAME\s+\.$" "$RPZ_FILE"; then
        echo "⚠️  Domain '$domain' is already blocked."
    else
        echo "${domain}.        CNAME   ." >> "$RPZ_FILE"
        echo "✅ Domain '$domain' has been added to $RPZ_FILE"
    fi
}

remove_domain() {
    local domain="$1"
    if grep -qE "^${domain}\.\s+CNAME\s+\.$" "$RPZ_FILE"; then
        sed -i "/^${domain}\.\s\+CNAME\s\+\./d" "$RPZ_FILE"
        echo "🟢 Domain '$domain' has been unblocked in $RPZ_FILE"
    else
        echo "ℹ️  Domain '$domain' was not found in $RPZ_FILE"
    fi
}

list_domains() {
    echo "📋 Currently blocked domains in $RPZ_FILE:"
    grep -E "CNAME\s+\.$" "$RPZ_FILE" | awk '{print $1}'
}

# ===== Main logic =====
init_file

case "$ACTION" in
    add)
        if [ -z "$DOMAIN" ]; then
            echo "Usage: $0 add <domain> [-f path_to_file]"
            exit 1
        fi
        add_domain "$DOMAIN"
        ;;
    remove)
        if [ -z "$DOMAIN" ]; then
            echo "Usage: $0 remove <domain> [-f path_to_file]"
            exit 1
        fi
        remove_domain "$DOMAIN"
        ;;
    list)
        list_domains
        ;;
    *)
        echo "Usage: $0 {add|remove|list} [domain] [-f path_to_file]"
        exit 1
        ;;
esac
