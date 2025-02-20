#!/bin/bash

# Выдели ip, url или домен нажми хоткей и получи инфу
# Зависимости: idn, dnsutils, whois
# Установка на хоткей (urxvt заменить на нужный терминал):
# urxvt -e sh -c "$HOME/dick.sh; /bin/bash"  - после выполнения скрипта консоль останется открытой
# urxvt -e sh -c "$HOME/dick.sh; /bin/bash -c read"  - при нажатии на enter терминал закроется

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
YELLOW_BOLD='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

BUFFER=$(xclip -o)
if [[ ${#BUFFER} -le 2 ]] || [[ ! `echo "$BUFFER" | grep "\."` ]]; then
  BUFFER=$1
  if [[ ${#BUFFER} -le 2 ]] || [[ ! `echo "$BUFFER" | grep "\."` ]]; then
    echo "Incorrect input"
    exit
  fi
fi

dig_manual() {
  echo "=========="
  clear
  echo -e "${YELLOW}`echo $BUFFER | awk '{print tolower($0)}'` ($DOMAIN_IDN)${NC}"
  echo -e "${CYAN}WHOIS:${NC} ${BLUE}$DOMAIN${NC}"
  echo -e "${CYAN}WHOIS DATA:${NC}"
  echo "$WHOIS"
  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

   # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi
}

dig_ip() {
  INFO=`whois $1`
  echo -e "${YELLOW}$1${NC}"
  echo "ptr:" `host $1 | awk '{print $NF}'`
  echo "inetnum:" `echo "$INFO" | grep -E "inetnum|NetRange" | awk -F":" '{print $2}' | sed -s "s/^[ \t]*//"`
  echo "route:" `echo "$INFO" | grep -E "route|CIDR" | awk -F":" '{print $2}' | sed -s "s/^[ \t]*//"`
  descr=$(echo "$INFO" | grep -Ew "descr|Organization|person" | awk -F":" '{print $2}' | sed -s "s/^[ \t]*//")
  echo "$descr" | sed -s "s/^/descr:/g"
  echo "origin:" `echo "$INFO" | grep -Ew "origin|OriginAS|aut-num" | awk -F":" '{print $2}' | sed -s "s/^[ \t]*//"`
  ping=$(ping -c1 -W1 $1)
  if [[ "$?" == 0 ]]; then echo "ping: OK"; else echo "ping: FALSE"; fi
}

dig_tk() {
  # check ns
  echo -e "${CYAN}NAME SERVERS:${NC}"
  ns=$(echo "$WHOIS" | grep -A 2 "Domain Nameservers" | grep -v "Domain Nameservers" | awk '{print tolower($0)}' | sed -s "s/^[ \t]*//")
  echo "$ns" | sed -s "s/^/\t/g"
  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi
}

dig_kz() {
  # check status
  echo -e "${CYAN}STATUS:${NC}"
  status=$(echo "$WHOIS" | grep "status" | sed -s "s/Domain status : //g" | sed -s "s/^[ \t]*//")
  while read state; do
    if [[ `echo "$state" | grep -iE 'clientHold|inactive'` ]]; then
      echo -e "\t${RED}$state${NC}"
    else
      echo -e "\t$state"
    fi
  done <<< "$status"

  # check ns
  echo -e "${CYAN}NAME SERVERS:${NC}"
  ns=$(echo "$WHOIS" | grep -E "Primary server|Secondary server" | awk -F":" '{print tolower($2)}' | sed -s "s/^[ \t]*//")
  echo "$ns" | sed -s "s/^/\t/g"
  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi
}

dig_it() {
  # check status
  echo -e "${CYAN}STATUS:${NC}"
  status=$(echo "$WHOIS" | grep "Status" | awk -F":" '{print $2}' | sed -s "s/^[ \t]*//")
  while read state; do
    if [[ `echo "$state" | grep -iE 'clientHold|inactive'` ]]; then
      echo -e "\t${RED}$state${NC}"
    else
      echo -e "\t$state"
    fi
  done <<< "$status"

  # check ns
  echo -e "${CYAN}NAME SERVERS:${NC}"
  ns=$(echo "$WHOIS" | grep -A 7 "Nameservers" | grep -v "Nameservers" | awk '{print tolower($0)}' | sed -s "s/^[ \t]*//")
  echo "$ns" | sed -s "s/^/\t/g"
  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi

  # Check paid domain
  paid=$(echo "$WHOIS" | grep -E "paid-till|Exp.* Date" | awk -F": " '{print $2}' | sed -s "s/^[ \t]*//" | head -n 1)
  echo -e "${CYAN}Paid to:${NC}"

  if [[ `date +%s` > `date -d $paid +%s` || `date +%F` == `echo $paid | awk -F"T" '{print $1}'` ]]; then
    echo -e "\t${RED}$paid${NC}"  # Истекло время оплаты
  elif [[ (`date +%m` == `echo $paid | awk -F"-" '{print $2-1}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ||\
          (`date +%m` == `echo $paid | awk -F"-" '{print $2}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ]]; then
    echo -e "\t${YELLOW_BOLD}$paid${NC}"  # Кончается время оплаты (меньше месяца)
  else
    echo -e "\t$paid"
  fi
}

dig_co_ua() {
  status=$(echo "$WHOIS" | grep -E 'Status' | sed -s "s/^[ \t]*//" | sort | uniq |\
           sed -s "s/.*://g")
  echo -e "${CYAN}STATUS:${NC}"
  while read state; do
    if [[ `echo "$state" | grep -iE 'clientHold|inactive'` ]]; then
      echo -e "\t${RED}$state${NC}"
    else
      echo -e "\t$state"
    fi
  done <<< "$status"

  # Check NS-servers
  ns=$(echo "$WHOIS" | grep -E 'Name Server' | awk '{print tolower($0)}' |\
       sed -s "s/.*://g" | sed -s "s/^[ \t]*//")

  echo -e "${CYAN}NAME SERVERS:${NC}"
  echo "$ns" | sed -s "s/^/\t/g"

  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  if [[ ! -z `echo "$ns" | head -n 1 | awk '{print $1}'` ]]; then
    ns1=$(echo "$ns" | head -n 1 | awk '{print $1}')
  else
    ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  fi
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi

  # Check paid domain
  paid=$(echo "$WHOIS" | grep -E "Exp.* Date" | sed -s "s/Exp.* Date://g" | sed -s "s/^[ \t]*//" | head -n 1)
  echo -e "${CYAN}Paid to:${NC}"

  if [[ `date +%s` > `date -d "$paid" +%s` || `date +%d-%b-%Y` == `echo "$paid" | grep -oE "[0-9]{2}-[A-Za-z]{3}-[0-9]{4}"` ]]; then
    echo -e "\t${RED}$paid${NC}"  # Истекло время оплаты
  elif [[ (`date +%b` == `echo $paid | awk -F"-" '{print $2-1}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ||\
          (`date +%b` == `echo $paid | awk -F"-" '{print $2}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ]]; then
    echo -e "\t${YELLOW_BOLD}$paid${NC}"  # Кончается время оплаты (меньше месяца)
  else
    echo -e "\t$paid"
  fi
}

dig_co_uk() {
  # check ns
  echo -e "${CYAN}NAME SERVERS:${NC}"
  ns=$(echo "$WHOIS" | grep -A 3 "Name servers" | grep -v "Name servers" | awk '{print tolower($0)}' | sed -s "s/^[ \t]*//")
  echo "$ns" | sed -s "s/^/\t/g"
  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi

  # Check paid domain
  paid=$(echo "$WHOIS" | grep -E "Exp.* date" | awk -F": " '{print $2}' | sed -s "s/^[ \t]*//" | head -n 1)
  echo -e "${CYAN}Paid to:${NC}"

  if [[ `date +%s` > `date -d $paid +%s` || `date +%d-%b-%Y` == `echo $paid` ]]; then
    echo -e "\t${RED}$paid${NC}"  # Истекло время оплаты
  elif [[ (`date +%b` == `echo $paid | awk -F"-" '{print $2-1}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ||\
          (`date +%b` == `echo $paid | awk -F"-" '{print $2}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ]]; then
    echo -e "\t${YELLOW_BOLD}$paid${NC}"  # Кончается время оплаты (меньше месяца)
  else
    echo -e "\t$paid"
  fi
}

dig_default() {
  # Check status domain
  status=$(echo "$WHOIS" | grep -E 'state|Domain Status|status' | grep -v "telephone" | sed -s "s/^[ \t]*//" | sort | uniq |\
           awk -F": " '{$1="";print}')
  if [[ `expr length "$status"` == 0 ]]; then
    dig_manual
    exit
  fi
  echo -e "${CYAN}STATUS:${NC}"
  while read state; do
    if [[ `echo "$state" | grep -iE 'clientHold|inactive'` ]]; then
      echo -e "\t${RED}$state${NC}"
    else
      echo -e "\t$state"
    fi
  done <<< "$status"

  # admin contact
  admin_contact=$(echo "$WHOIS" | grep admin-contact | sed -s "s/^[ \t]*//" | sort | uniq |\
                  awk -F": " '{$1="";print}')
  if [[ ! -z `echo "$admin_contact"` ]]; then
    echo -e "${CYAN}Admin contact:${NC}"
    echo -e "\t$admin_contact"
  fi

  # Check NS-servers
  ns=$(echo "$WHOIS" | grep -E 'nserver|Name Server' | awk '{print tolower($0)}' |\
       awk -F": " '{$1="";print}' | sed -s "s/^[ \t]*//")
  if [[ `expr length "$ns"` == 0 ]]; then
    dig_manual
    exit
  fi
  echo -e "${CYAN}NAME SERVERS:${NC}"
  echo "$ns" | sed -s "s/^/\t/g"

  # Check A-records
  echo -e "${CYAN}A-records:${NC}"
  echo -e "\t${BLUE}@fvds:${NC}" `dig +short $DOMAIN_IDN @ns1.firstvds.ru`  # FirstVDS NS
  echo -e "\t${BLUE}@ispvds:${NC}" `dig +short $DOMAIN_IDN @ns1.ispvds.com`  # ISPserver NS

  if [[ ! -z `echo "$ns" | head -n 1 | awk '{print $1}'` ]]; then
    ns1=$(echo "$ns" | head -n 1 | awk '{print $1}')
  else
    ns1=$(echo "$ns" | head -n 1 | awk '{print $NF}')
  fi
  echo -e "\t${BLUE}@ns:${NC}" `dig +short $DOMAIN_IDN @$ns1`  # Domain NS

  # Check public DNS
  echo -e "\t${BLUE}@8.8.8.8:${NC}" `dig +short $DOMAIN_IDN @8.8.8.8`  # Google NS
  echo -e "\t${BLUE}@1.1.1.1:${NC}" `dig +short $DOMAIN_IDN @1.1.1.1`  # Cloudfalre NS

  # Check MX-records
  echo -e "${CYAN}MX-records:${NC}"
  mx=$(dig +short $DOMAIN_IDN mx)
  echo "$mx" | sed -s "s/^/\t/g"

  if [[ ! -z $mx ]]; then
    # Check A-record on MX
    mx1=$(echo "$mx" | head -n 1 | awk '{print $2}')
    if [[ -z $mx1  ]]; then
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $1}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $1}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    else
      echo -e "${CYAN}A-record - ${BLUE}`echo "$mx" | head -n 1 | awk '{print $2}'`${CYAN}:${NC}"
      mx_a=$(dig +short `echo "$mx" | head -n 1 | awk '{print $2}'`)
      echo "$mx_a" | sed -s "s/^/\t/g"
    fi
  fi

  # Check paid domain
  paid=$(echo "$WHOIS" | grep -E "paid-till|Exp.* Date|expires" | awk -F": " '{print $2}' | sed -s "s/^[ \t]*//" | head -n 1)
  echo -e "${CYAN}Paid to:${NC}"

  if [[ `date +%s` > `date -d "$paid" +%s` || `date +%F` == `echo "$paid" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}"` ]]; then
    echo -e "\t${RED}$paid${NC}"  # Истекло время оплаты
  elif [[ (`date +%m` == `echo $paid | awk -F"-" '{print $2-1}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ||\
          (`date +%m` == `echo $paid | awk -F"-" '{print $2}'` && `date +%Y` == `echo $paid | awk -F"-" '{print $1}'`) ]]; then
    echo -e "\t${YELLOW_BOLD}$paid${NC}"  # Кончается время оплаты (меньше месяца)
  else
    echo -e "\t$paid"
  fi
}

ping_dom() {
  echo -e "${CYAN}Ping:${NC}"
  ping=$(ping -c1 -W1 $BUFFER | head -n2)
  echo -e "$ping" | sed -s "s/^/\t/g"
}


if [[ `echo $BUFFER | grep "http"` ]]; then
  if [[ `echo $BUFFER | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'` ]]; then
    ip=$(echo "$BUFFER" | awk -F[/:] '{print $4}')
    dig_ip $ip
    exit
  else
    BUFFER=$(echo "$BUFFER" | awk -F[/:] '{print $4}')
  fi
elif [[ `echo $BUFFER | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'` ]]; then
  dig_ip $BUFFER
  exit
else
  if [[ `echo $BUFFER | grep '/'` ]]; then
    BUFFER=$(echo "$BUFFER" | awk -F'/' '{print $1}')
  fi
fi


export CHARSET=UTF-8
DOMAIN_IDN=$(echo $BUFFER | awk '{print tolower($0)}' | xargs idn)
DOMAIN=$DOMAIN_IDN
WHOIS=$(timeout 15 whois $DOMAIN 2>&1)
if [[ "$?" == 124 ]]; then
  dig_manual
  exit
fi
while [[ ! `echo "$WHOIS" | grep -v "Query string" | grep -i DOMAIN` || `echo "$WHOIS" | grep -E "No match for|NOT FOUND"` || `echo "$DOMAIN" | grep "^www."` ]]; do
  DOMAIN=$(echo "$DOMAIN"| awk -F"." '{$1="";print $0}' | sed -s "s/ /./g" | sed -s "s/^\.//g")
  WHOIS=$(timeout 15 whois $DOMAIN 2>&1)
  if [[ "$?" == 124 ]]; then
    dig_manual
    exit
  fi
done

echo -e "${YELLOW}`echo $BUFFER | awk '{print tolower($0)}'` ($DOMAIN_IDN)${NC}"
echo -e "${CYAN}WHOIS:${NC} ${BLUE}$DOMAIN${NC}"

# check exist domain
if [[ `echo "$WHOIS" | grep "domain name not known"` || `echo "$WHOIS" | grep "No entries found for the selected source(s)."` ]]; then
  echo -e "${YELLOW}Домен не зарегистрирован${NC}"
  exit
# DIG .tk domain
elif [[ `echo $DOMAIN | awk -F"." '{print $NF}'` == "tk" ]]; then
  dig_tk
  ping_dom
  exit
# DIG .kz domain
elif [[ `echo $DOMAIN | awk -F"." '{print $NF}'` == "kz" ]]; then
  dig_kz
  ping_dom
  exit
# DIG .it domain
elif [[ `echo $DOMAIN | awk -F"." '{print $NF}'` == "it" ]]; then
  dig_it
  ping_dom
  exit
# DIG .co.ua
elif [[ `echo $DOMAIN | awk -F"." '{print $(NF-1) FS $NF}'` == "co.ua" ]]; then
  dig_co_ua
  ping_dom
  exit
# DIG .co.uk
elif [[ `echo $DOMAIN | awk -F"." '{print $(NF-1) FS $NF}'` == "co.uk" ]]; then
  dig_co_uk
  ping_dom
  exit
else
# DIG ru, su, рф, com и т.д
  dig_default
  ping_dom
  exit
fi
