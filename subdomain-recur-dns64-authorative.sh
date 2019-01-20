#!/bin/sh

DEBUG=1

DOMAIN="re.example.com"
PREFIX="64:ff9b::"
NS="ns.re.example.com"
ADMIN="admin.re.example.com"
TTL=60

SOA="$NS\t$ADMIN\t2019011900\t$TTL\t$TTL\t$TTL\t$TTL"

log_err() {
    echo $@ >&2
}

get_record() {
    local type=$1
    local content=$2
    printf "DATA\t$QNAME\t$QCLASS\t$type\t$TTL\t$ID\t$content\n"
}

is_ip_part() {
    local str=$1
    case "$str" in
        ''|*[!0-9]*) return 1 ;;
        *) [ $str -lt 256 ] ;;
    esac
}

is_ip() {
    IFS='.' read -r a b c d
    is_ip_part $a && is_ip_part $b && is_ip_part $c && is_ip_part $d
}

ivi96() {
    IFS='.' read -r a b c d
    printf "$PREFIX%02x%02x:%02x%02x\n" $a $b $c $d
}

while true; do
    read -r helo ver
    if [ $helo != "HELO" ]; then
        log_err "No HELO: $helo $ver"
        echo FAIL
        exit 1
    elif [ $ver != "1" ]; then
        log_err "Unsupported abi version $ver"
        echo FAIL
    else
        printf "OK\tRE6!\n"
        break
    fi
done

while true; do
    read -r CMD QNAME QCLASS QTYPE ID REMOTE_IP
    if [ z"$CMD" != zQ ]; then
        log_err "Unknown cmd $CMD"
        echo FAIL
        continue
    fi
    name=${QNAME%%.$DOMAIN}
    if [ z"$DEBUG" == z1 ]; then
        log_err "$CMD $QNAME $name $QTYPE"
    fi
    if [ z"$QTYPE" == zSOA ]; then
        get_record SOA "$SOA"
        echo END
        continue
    fi
    if echo $name | is_ip; then
        a_records=$name
        aaaa_records=""
    else
        result=$(getent ahosts $name 2>/dev/null| grep DGRAM | awk '{print $1}')
        a_records=$(echo "$result" | grep -v ':')
        aaaa_records=$(echo "$result" | grep ':')
    fi
    if [ z"$QTYPE" == zSOA ] || [ z"$QTYPE" == zANY ]; then
        get_record SOA "$SOA"
    fi
    if [ z"$QTYPE" == zA ] || [ z"$QTYPE" == zANY ]; then
        for r in $a_records; do
            get_record A $r
        done
    fi
    if [ z"$QTYPE" == zAAAA ] || [ z"$QTYPE" == zANY ]; then
        if [ z"$aaaa_records" == z ]; then
            aaaa_records=$(for r in $a_records; do echo $r | ivi96; done)
        fi
        for r in $aaaa_records; do
            get_record AAAA $r
        done
    fi
    echo END
done
