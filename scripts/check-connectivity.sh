#!/usr/bin/env bash

set -u
interface="enp0s8"
server_ip="192.168.50.1"

echo "Sprawdzanie sieci labolatoryjnej"
echo "Komputer $(hostname)"
echo "Interfejs: $interface"

if ! ip -4 addr show dev "$interface"; then
   echo "FAIL: nie mozna odczytac interfejsu"
   exit 1
fi

echo
echo "Sprawdzam polaczenie z serwerem $server_ip ..."

if ping -I "$interface" -c 4 -W 2 "$server_ip"; then
   echo "PASS: serwer odpowiada przez $interface."
else
   echo "FAIL: brak odpowiedzi serwera przez $interface."
   exit 1
fi

echo
echo "Sprawdzam DNS dla server.lab.test..."

resolved_ip="$(getent ahostsv4 server.lab.test | awk 'NR == 1 {print $1}')"

if [[ "$resolved_ip" == "$server_ip" ]]; then
   echo "PASS: DNS zwraca oczekiwany adres $server_ip."
else
   echo "FAIL: oczekiwano $server_ip, otrzymano: ${resolved_ip:-brak adresu}."
   exit 1
fi


echo 
echo "Sprawdzam domyslna brame IPv4..."

default_route="$(ip -4 route show default)"

if [[ "$default_route" == "default via $server_ip dev $interface "* ]]; then
   echo "PASS: brama domyslna prowadzi przez $server_ip."
else
   echo "FAIL: nieoczekiwana trasa: ${default_route:-brak trasy}."
   exit 1
fi
