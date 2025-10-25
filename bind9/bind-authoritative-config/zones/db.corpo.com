$TTL 1h
@   IN  SOA ns1.corpo.com. admin.corpo.com. (
        2025102501 ; Serial (YYYYMMDDNN — increment on every change)
        1h          ; Refresh
        15m         ; Retry
        30d         ; Expire
        2h )        ; Minimum TTL

; ====== Nameservers ======
    IN  NS  ns1.corpo.com.
    IN  NS  ns2.corpo.com.

; ====== A / AAAA records ======
@           IN  A       203.0.113.10       ; main website
ns1         IN  A       203.0.113.11
ns2         IN  A       203.0.113.12
mail        IN  A       203.0.113.20
vpn         IN  A       203.0.113.30
www         IN  CNAME   corpo.com.

; ====== MX (Mail) ======
@           IN  MX 10   mail.corpo.com.

; ====== TXT (SPF, DKIM, etc.) ======
@           IN  TXT     "v=spf1 mx a ~all"
_dmarc      IN  TXT     "v=DMARC1; p=none; rua=mailto:dmarc@corpo.com"

; ====== Optional IPv6 records ======
@           IN  AAAA    2001:db8::10
ns1         IN  AAAA    2001:db8::11
ns2         IN  AAAA    2001:db8::12
