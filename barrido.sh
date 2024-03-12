#!/bin/bash

printf "  /\\_/\\  \n"
printf " (='.'=) \n"
printf "  (\\\" )_(\\\")\n"
printf " by @condor\n"

RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'

# Verificar si arp-scan está instalado
if ! command -v arp-scan &> /dev/null; then
    printf "${RED}[+] arp-scan no está instalado. Instalándolo...${RESET}\n"
    sudo apt-get update
    sudo apt-get install -y arp-scan
fi

# Preguntar al usuario por la interfaz de red
read -p "Ingrese el nombre de la interfaz de red (por ejemplo, eth0, ens33): " interfaz

# Comprobar si se proporcionó un nombre de interfaz válido
if [ -z "$interfaz" ]; then
    printf "${RED}[+] Debe ingresar un nombre de interfaz de red válido.${RESET}\n"
    exit 1
fi

# Realizar el escaneo ARP y obtener la IP y MAC de la máquina
result=$(sudo arp-scan -I $interfaz --localnet --ignoredups)

# Extraer la IP y MAC
ip=$(echo "$result" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n 1)
mac=$(echo "$result" | grep -oP '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})' | head -n 1)

if [ -z "$ip" ] || [ -z "$mac" ]; then
    printf "${RED}[+] No se encontraron máquinas virtuales para analizar.${RESET}\n"
    exit 1
fi

printf "${GREEN}[+] La IP de la máquina es ${RED}$ip${RESET}\n"
printf "${GREEN}[+] La MAC de la máquina es ${RED}$mac${RESET}\n"

# Realizar un ping a la IP para obtener el TTL
ttl_value=$(ping -c1 $ip | grep 'ttl' | awk '{print $6}' | cut -d '=' -f 2)

# Verificar el sistema operativo basado en el TTL
if [ "$ttl_value" -eq 64 ]; then
    printf "${GREEN}[+] El sistema operativo es ${RED}Linux${RESET}\n"
else
    printf "${GREEN}[+] El sistema operativo es ${RED}Windows o podría ser otra plataforma${RESET}\n"
fi
