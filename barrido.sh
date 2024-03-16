#!/bin/bash

# Función para limpieza antes de salir del script
cleanup() {
    printf "\n${RED}[+] Saliendo del script...\n${RESET}"
    # Agrega aquí cualquier limpieza necesaria antes de salir del script
    exit 1
}

# Definir la acción a realizar al recibir la señal SIGINT (Ctrl+C)
trap cleanup SIGINT

printf "\e[1;92m  /\\_/\\  \n"
printf " (='.'=) \n"
printf "  (\\\" )_(\\\")\n"
printf " by @CondorHacks\n\e[0m"

# Mención especial para CuriosidadesDeHackers por su colaboración 

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
RESET='\e[0m'

# Verificar si arp-scan está instalado
if ! command -v arp-scan &> /dev/null; then
    printf "${RED}[+] arp-scan no está instalado. Instalándolo...${RESET}\n"
    sudo apt-get update
    sudo apt-get install -y arp-scan
fi

# Imprimir mensaje de entrada en amarillo con el símbolo al principio
printf "${YELLOW}\uf071 Introduce los nombres de las interfaces de red separados por comas (por ejemplo, eth0,ens8)\n"

# Leer la entrada del usuario
IFS= read -re interfaces </dev/tty

# Imprimir el símbolo al final
printf "\uf071\n"

# Convertir la cadena de interfaces separadas por comas en un array
IFS=',' read -ra interface_array <<< "$interfaces"

# Iterar sobre cada interfaz
for interfaz in "${interface_array[@]}"; do
    # Comprobar si se proporcionó un nombre de interfaz válido
    if [ -z "$interfaz" ]; then
        printf "${RED}[+] Debes ingresar un nombre de interfaz de red válido.${RESET}\n"
        exit 1
    fi

    printf "${BLUE}[+] Escaneando en la interfaz ${YELLOW}$interfaz${RESET}\n"

    # Obtener la MAC de la interfaz de red especificada
    mi_mac=$(ifconfig $interfaz 2>/dev/null | awk '/ether/{print $2}')

    # Realizar el escaneo ARP y obtener la IP y MAC de las máquinas
    result=$(sudo arp-scan -I $interfaz --localnet --ignoredups 2>/dev/null | grep -v "$mi_mac" | grep -E '00:0c|08:00')

    # Verificar si se encontraron resultados en la interfaz
    if [ -z "$result" ]; then
        printf "${RED}[+] No se encontró nada en la interfaz $interfaz.${RESET}\n"
        continue
    fi

    # Extraer la IP y MAC
    while IFS= read -r line; do
        ip=$(echo "$line" | awk '{print $1}')
        mac=$(echo "$line" | awk '{print $2}')

        printf "${GREEN}[+] La IP de la máquina es ${RED}$ip${RESET}\n"
        printf "${GREEN}[+] La MAC de la máquina es ${RED}$mac${RESET}\n"

        # Realizar un ping a la IP para obtener el TTL
        ttl_value=$(ping -c1 $ip 2>/dev/null | grep 'ttl' | awk '{print $6}' | cut -d '=' -f 2)

        # Verificar el sistema operativo basado en el TTL
        if [ -z "$ttl_value" ]; then
            printf "${RED}[+] Error al obtener el TTL para $ip.${RESET}\n"
        else
            if [ "$ttl_value" -eq 64 ]; then
                printf "${GREEN}[+] El sistema operativo de $ip es ${RED}Linux${RESET} \ue712 \n"

                # Preguntar al usuario si desea realizar un escaneo básico con Nmap
                printf "${GREEN}[+] ¿Quieres hacer un escaneo básico de esta IP $ip (Y/N)? :${RESET}"
                read -re respuesta </dev/tty
                respuesta=$(echo "$respuesta" | tr '[:upper:]' '[:lower:]')
                if [ "$respuesta" == "y" ]; then
                    # Realizar un escaneo básico con Nmap
                    resultado_nmap=$(sudo nmap -sSCV -n -Pn --min-rate 5000 -p- --open $ip)
                    printf "${GREEN}[+] Resultado del escaneo Nmap para ${RED}$ip${RESET}:\n$resultado_nmap\n"
                    printf "${GREEN}[+] Escaneo de Nmap finalizado\n"
                    printf "\n"  # Añadir espacio después del escaneo Nmap
                elif [ "$respuesta" == "n" ]; then
                    printf "${GREEN}[+] No se realizó escaneo para ${RED}$ip${RESET}\n"
                    printf "\n"  # Añadir espacio antes de la próxima IP
                else
                    printf "${GREEN}[+] Opción no válida. No se realizó escaneo para ${RED}$ip${RESET}\n"
                    printf "\n"  # Añadir espacio antes de la próxima IP
                fi
            else
                printf "${GREEN}[+] El sistema operativo de $ip es ${RED}Windows \ue70f \n"

                # Preguntar al usuario si desea realizar un escaneo básico con Nmap
                printf "${GREEN}[+] ¿Quieres hacer un escaneo básico de esta IP $ip (Y/N)? :${RESET}"
                read -re respuesta </dev/tty
                respuesta=$(echo "$respuesta" | tr '[:upper:]' '[:lower:]')
                if [ "$respuesta" == "y" ]; then
                    # Realizar un escaneo básico con Nmap
                    resultado_nmap=$(sudo nmap -sSCV -n -Pn --min-rate 5000 -p- --open $ip)
                    printf "${GREEN}[+] Resultado del escaneo Nmap para ${RED}$ip${RESET}:\n$resultado_nmap\n"
                    printf "${GREEN}[+] Escaneo de Nmap finalizado\n"
                    printf "\n"  # Añadir espacio después del escaneo Nmap
                elif [ "$respuesta" == "n" ]; then
                    printf "${GREEN}[+] No se realizó escaneo para ${RED}$ip${RESET}\n"
                    printf "\n"  # Añadir espacio antes de la próxima IP
                else
                    printf "${GREEN}[+] Opción no válida. No se realizó escaneo para ${RED}$ip${RESET}\n"
                    printf "\n"  # Añadir espacio antes de la próxima IP
                fi
            fi
        fi
    done <<< "$result"
done
