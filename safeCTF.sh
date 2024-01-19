#!/bin/bash

# Colors
b="\e[1m"
w="\e[0m"
r="\e[31m"
d="\e[2m"

# Banner
logo="$b
                          _cyqyc_
                      :>3qKKKKKKKq3>:
                  ';CpKKKKKKKkKKKKKKKpC;'
              -\"iPKKKKKKkkkCZ3R0KKKKKKKKKKPi\"-
          \`~v]KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK]v~\`
       ,rwKKKKKKKKKKKKKPv;,:'-':,;vPKKKKKKKKKKKKKwr,
      !KKKKKKKKKKKKKKK/             !KKKKKKKKKKKKKKK!
      !KKKKKKKKKKKKKKf       ?       CKKKKKKKKKKKKKK!
      !KKKKKKKKKKKKKp-               -qKKKKKKKKKKKKK!
      !KKKKKKKKKKKKK>\"               \"\\KKKKKKKKKKKKK!
      !KKKKKKKw;,_'-                   .-:,\"wKKKKKKK!
      !KKKKKKKKhi*;\"                   \";*ihKKKKKKKK!
      !KKKKKKKKKKKKK;                 ;KKKKKKKKKKKKK!
      !KKKKKKKKKKKKK2>'             '>2KKKKKKKKKKKKK!
      !KKKKKKKKKKKKKKKZ             ZKKKKKKKKKKKKKKK!
      !KKKKKKKKKKKKKKK5             eKKKKKKKKKKKKKKK!
      !KKKKKKKKKKKqC;-               -;CqKKKKKKKKKKK!
      <KKKKKKKKkr,                       ,rSKKKKKKKK<
       -\"v]qj;-                             -;jq]v\"-
                        $w[SafeCTF]$w
            $d Configuration iptables for CTF
                  $d by $w$r@Commander.Z3R0$w"

echo -e "$logo"


function ctrl_c(){
	echo -e "\n\n[!] Exiting...\n"
	exit 1

}

#CTRL+C
trap ctrl_c INT

# VPN IP address (pass the IP address as an argument to the script)
VPN_IP=$1

# Function to display script usage
mostrar_ayuda() {
  echo "       [*] Usage: $0 [-h|--help] <VPN_IP>"
  echo ""
  echo "       [*] Options:"
  echo "            -h, --help    Show this help message"
  echo "            <VPN_IP>      VPN IP address (required)"
  echo ""
  echo "       [*] Example:"
  echo "           $0 IP_Address"
}

# Check if the script was called with -h or --help
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  mostrar_ayuda
  exit 0
fi

#echo -e "$logo"

# Verify privileges
if [ "$EUID" -ne 0 ]; then
  echo "      [!] Please execute the script with privileges."
  exit 1
fi


# Check if the VPN IP address has been provided
if [ -z "$VPN_IP" ]; then
  echo "Please provide the VPN IP address as an argument to the script."
  echo ""
  mostrar_ayuda
  exit 1
fi

# Function to clean rules and chains
limpiar_reglas() {
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -t nat -F
  iptables -t mangle -F
  iptables -F
  iptables -X
  iptables -Z

  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT DROP
  ip6tables -t nat -F
  ip6tables -t mangle -F
  ip6tables -F
  ip6tables -X
  ip6tables -Z
}

# Function to set ping rules
reglas_ping() {
  iptables -A INPUT -p icmp -i tun0 -s "$VPN_IP" --icmp-type echo-request -j ACCEPT
  iptables -A INPUT -p icmp -i tun0 -s "$VPN_IP" --icmp-type echo-reply -j ACCEPT
  iptables -A INPUT -p icmp -i tun0 --icmp-type echo-request -j DROP  
  iptables -A INPUT -p icmp -i tun0 --icmp-type echo-reply -j DROP

  iptables -A OUTPUT -p icmp -o tun0 -d "$VPN_IP" --icmp-type echo-reply -j ACCEPT
  iptables -A OUTPUT -p icmp -o tun0 -d "$VPN_IP" --icmp-type echo-request -j ACCEPT
  iptables -A OUTPUT -p icmp -o tun0 --icmp-type echo-request -j DROP
  iptables -A OUTPUT -p icmp -o tun0 --icmp-type echo-reply -j DROP
}

# Function to allow VPN connection only from specified machine
permitir_vpn() {
  iptables -A INPUT -i tun0 -p tcp -s "$VPN_IP" -j ACCEPT
  iptables -A OUTPUT -o tun0 -p tcp -d "$VPN_IP" -j ACCEPT
  iptables -A OUTPUT -o tun0 -p udp -d "$VPN_IP" -j ACCEPT
  iptables -A INPUT -i tun0 -j DROP
  iptables -A OUTPUT -o tun0 -j DROP
}

# Call the functions
limpiar_reglas
reglas_ping
permitir_vpn


echo "          [+] The process finished successfully. "

mostrar_reglas() {
  echo -n "[*] Do you want to display the iptables rules? (yes/no): "
  read -r respuesta
  echo "[?] : $respuesta"
  if [ "$respuesta" == "yes" ]; then
    echo "[#] IPv4 iptables rules:"
    iptables -L
    echo ""
    echo "[#] IPv6 ip6tables rules:"
    ip6tables -L
  else
    echo "[-] iptables rules not displayed."
  fi
}


resetear_iptables() {
  echo -n "[*] Do you really want to reset iptables to default settings? (yes/no): "
  read -r respuesta
  echo "[?] : $respuesta"
  if [ "$respuesta" == "yes" ]; then
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -F
    iptables -t mangle -F
    iptables -F
    iptables -X
    iptables -Z

    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -t nat -F
    ip6tables -t mangle -F
    ip6tables -F
    ip6tables -X
    ip6tables -Z

    echo "[+] iptables reset to default settings."
  else
    echo "[-] iptables reset canceled."
  fi
}


mostrar_reglas2() {
  echo -n "[*] Do you want to display the iptables rules? (yes/no): "
  read -r respuesta
  echo "[?] : $respuesta"
  if [ "$respuesta" == "yes" ]; then
    echo "[#] IPv4 iptables rules:"
    iptables -L
    echo ""
    echo "[#] IPv6 ip6tables rules:"
    ip6tables -L
  else
    echo "[-] iptables rules not displayed."
  fi
}


# Save the rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Ask user if they want to display iptables rules
mostrar_reglas
# Ask user if they want to reset iptables rules
resetear_iptables
# Ask user if they want to display iptables rules after reset
mostrar_reglas2
