#!/bin/bash

DEF='\033[0;39m'       #  ${DEF}
DGRAY='\033[1;30m'     #  ${DGRAY}
LRED='\033[1;31m'      #  ${LRED}
LGREEN='\033[1;32m'    #  ${LGREEN}
LYELLOW='\033[1;33m'   #  ${LYELLOW}
LBLUE='\033[1;34m'     #  ${LBLUE}
LMAGENTA='\033[1;35m'  #  ${LMAGENTA}
LCYAN='\033[1;36m'     #  ${LCYAN}
WHITE='\033[1;37m'     #  ${WHITE}

set -o pipefail

echo -ne "\n"
echo -ne "\n${LGREEN}!================================================================================!"
echo -ne "\n"

# SYSTEM INFO

kern=$(uname -s)
case "${kern}" in
	        Linux)
                if [ -f /etc/redhat-release ]; then
                        RELEASE=$(sed -n 's/^\([A-Za-z]*\)[^0-9]*\([0-9]*\).*/\1 \2/p' /etc/redhat-release)
                elif [ -f /etc/centos-release ]; then
                        RELEASE=$(sed -n 's/^\([A-Za-z]*\)[^0-9]*\([0-9]*\).*/\1 \2/p' /etc/centos-release)
                elif [ -f /etc/oracle-release ]; then
                        RELEASE=$(sed -n 's/^\([A-Za-z]*\)[^0-9]*\([0-9]*\).*/\1 \2/p' /etc/oracle-release)
	              elif [ -f /etc/rocky-release ]; then
                        RELEASE=$(sed -n 's/^\([A-Za-z]*\)[^0-9]*\([0-9]*\).*/\1 \2/p' /etc/rocky-release)
                elif [ -f /etc/system-release ]; then
                        RELEASE=$(sed -n 's/^\([A-Za-z]*\)[^0-9]*\([0-9]*\).*/\1 \2/p' /etc/system-release)
                elif [ "lsb_release -d" ]; then
                        RELEASE=$(lsb_release -d 2> /dev/null | awk -F ':\t' '{print $2}')
                elif [ -f /etc/os-release ]; then
                        RELEASE=$((grep -w NAME /etc/os-release| awk -F= '{print $2}' && grep -w VERSION_ID /etc/os-release| awk -F= '{ print $2 }')| tr -s '\n' ' ' | tr -d \")
                fi
                ;;
        FreeBSD)
                if [ -f /etc/os-release ]; then
                        RELEASE=$((grep -w NAME /etc/os-release| awk -F= '{print $2}' && grep -w VERSION_ID /etc/os-release| awk -F= '{ print $2 }')| tr -s '\n' ' ' | tr -d \")
	              fi
                ;;
esac

if [[ -f /proc/user_beancounters ]]; then
    PLATFORM="VM OVZ"
elif [[ `cat /proc/cpuinfo  | grep -w hypervisor` ]]; then
    PLATFORM="VM KVM"
else
    PLATFORM="DEDIC"
fi
CPU_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)
MEM_TOTAL=$(( $(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }') / 1024 ))
SWAP=$(( $(cat /proc/meminfo | grep SwapTotal | awk '{ print $2 }') / 1024 ))
echo -ne "${LGREEN}System info:${DEF} "
echo -ne "[${LCYAN}$PLATFORM${DEF}]  $RELEASE   CPU: $CPU_COUNT    RAM: $MEM_TOTAL MB    SWAP: $SWAP MB\n"

# LOAD
WA=$(vmstat|tail -n1|awk '{print $16}')
LA1=$(cat /proc/loadavg |cut -d' ' -f1)
LA5=$(cat /proc/loadavg |cut -d' ' -f2)
LA15=$(cat /proc/loadavg |cut -d' ' -f3)
echo -ne "${LGREEN}Load: ${DEF}"
echo -ne "LA: $LA1 $LA5 $LA15    WA: $WA\n"

# DISK
DTOTAL=$(df -h / |tail -n1|awk '{print $2}')
DUSAGE=$(df -h / |tail -n1|awk '{print $3}')
DFREE=$(df -h / |tail -n1|awk '{print $4}')
echo -ne "${LGREEN}Disk: ${DEF}"
echo -ne "Total: $DTOTAL    Usage: $DUSAGE    "
if [[ `df -h | grep -w "/" | awk '{print $5}' | sed -s 's/%//g'` > 90 ]]; then
    echo -ne "${LRED}Free: $DFREE (<90%)${DEF}    "
else
    echo -ne "Free: $DFREE    "
fi

# INNODE
if [[ `df -i | grep -w "/" | awk '{print $5}' | sed -s 's/%//g'` > 90 ]]; then
    echo -ne "${LGREEN}Innode usage: ${DEF}${LRED}$(df -i / | awk '{print $5}' | tail -n1) (<90%)${DEF}\n"
else
    echo -ne "${LGREEN}Innode usage: ${DEF}$(df -i / | awk '{print $5}' | tail -n1)\n"
fi

# NUMFILE
if [[ -f /proc/user_beancounters ]]; then
    NUM_LIM=$(grep 'numfile' /proc/user_beancounters|awk '{print $5}')
    NUM_CUR=$(grep 'numfile' /proc/user_beancounters|awk '{print $3}')
    NUM_ERR=$(grep 'numfile' /proc/user_beancounters|awk '{print $NF}')
    echo -ne "${LGREEN}Numfile: ${DEF}"
    echo -ne "Limit: $NUM_LIM    Current: $NUM_CUR    Error: $NUM_ERR\n"
fi

# MySQL
if command -v mysql &> /dev/null
then
    mysql --version &> /dev/null
    if mysql --version | grep MariaDB &> /dev/null
    then
        MARIADB_VER=$(mysql --version | awk '{print $5}' | tr -d ,)
        echo -ne "${LGREEN}MariaDB: ${DEF}$MARIADB_VER\n"
    else
        MYSQL_VER=$(mysql --version | awk '{print $3}')
        echo -ne "${LGREEN}MySQL: ${DEF}$MYSQL_VER\n"
    fi
else
    echo -ne "${LGREEN}MySQL: ${LRED}not installed\n"
fi

#PHP
PHP_VER=$(php -v 2> /dev/null | grep PHP |grep -v Copyright | awk '{print $1,$2}' || echo -ne "${LRED}not installed${DEF}")
echo -ne "${LGREEN}PHP: ${DEF}$PHP_VER\n"

#Panel
if [ -d /usr/local/mgr5/ ]; then
        PANEL="$(/usr/local/mgr5/bin/core ispmgr -F) $(/usr/local/mgr5/bin/core ispmgr -V | cut -d "-" -f 1) $(cat /usr/local/mgr5/etc/repo.version)"
elif [ -d /usr/local/ispmgr/ ]; then
        PANEL="ISPmanager 4"
elif [ -d /usr/local/vesta/ ]; then
        PANEL=VESTA
elif [ -d /usr/local/cpanel/ ]; then
        PANEL=CPANEL
elif [ -s /opt/webdir/bin/bx-sites ]; then
        BITRIX_ENV=$(grep BITRIX_VA_VER /etc/profile | awk -F'=' '{print $2}')
        PANEL="Bitrix Env $BITRIX_ENV"
elif [ -d /etc/nginx/bx ]; then
        PANEL="Bitrix GT Turbo"
elif [ -d /opt/node_modules/push-server/  ] || [ -f /etc/nginx/sites-available/rtc.conf ]; then
        PANEL="Bitrix Setup"
else
        PANEL=${LRED}"not detected"
fi

echo -en "${LGREEN}Panel: ${DEF}${PANEL}\n"
echo -ne "${LGREEN}================================================================================"

MAIN_MENU() {
    echo -ne "\n"
    echo -ne "${LGREEN}\n Что делаем?\n${DEF}"
    echo -ne "\n"

    script[0]='Выход'
    script[1]='Debug'
    script[2]='Tools'
    script[3]='ISP_MENU'
    script[4]='BITRIX_MENU'

for index in ${!script[*]}
do
    printf "%4d: %s\n" $index ${script[$index]}
done
}

ISP_MENU() {
  MENU() {
    echo -ne "\n"
    echo -ne "${LGREEN}\n ISP menu:\n${DEF}"
    echo -ne "\n"

    script_isp[1]='Подложить ключ ISPmanager5'
    script_isp[2]='Составить hosts из webdomain'
    script_isp[3]='Обновить панель'
    script_isp[4]='Установить панель ISPmanager5'
    script_isp[5]='Получить список доменов'
    script_isp[6]='Chown на /var/www/$USER/data/www'
    script_isp[7]='Массовое диганье доменов'
    script_isp[0]='Вернуться в меню'

    for index in ${!script_isp[*]}; do
      printf "%4d: %s\n" $index "${script_isp[$index]}"
    done
  }

    MENU
    echo -ne "\n"
    read -r -p "Choose: " payload
    case $payload in
    0)
	return ;;
    1)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/ispmgr_go.sh)
	return
	;;
    2)
        echo -ne "\n"
        echo -ne "Перенос данных выполнен, проверить работу сайтов, не меняя записи ДНС, можно прописав на локальном ПК в файле hosts (C:\Windows\System32\drivers\etc\hosts) следующие данные:"
        for i in `/usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk -F'ipaddr=|name=| ' '{print $(NF-2)"::"$3}'`   ; do idn=$(echo $i|awk -F'::' '{print $NF}'|xargs python -c 'import sys;print (sys.argv[1].decode("utf-8").encode("idna"))'); echo "`echo $i | awk -F'::' '{print $1}'` $idn www.$idn"; done
        echo -ne "\n"
        echo -ne "FirstVDS: Подробнее на нашем сайте - https://firstvds.ru/technology/check-after-transfer\n"
        echo -ne "ISPserver: Подробнее на нашем сайте - https://ispserver.ru/help/proverka-dostupnosti-sayta-posle-perenosa\n"
        echo -ne "Если все корректно - смените ДНС записи на ip нового сервера, если не знаете как это сделать сообщите нам, поможем."
        echo
        echo
        return
	;;
    3)
       /usr/local/mgr5/bin/core -V; /usr/local/mgr5/bin/core ispmgr -V; cat  /usr/local/mgr5/etc/repo.version; /usr/local/mgr5/sbin/licctl info ispmgr|grep Latest
	echo -e 'Latest-beta' $(curl http://cdn.ispsystem.com/repo.versions| tail -1)
	printf "Обновляем панель (y/n)?: ";
	read STATE;

	if ([ $STATE = "y" ] || [ $STATE = "yes" ])
        then
        /usr/local/mgr5/sbin/pkgupgrade.sh ispmanager-lite-common;
	else
        echo "Кто вообще придумал эти обновления?";
        exit 0;
	fi
	return
        ;;
    4)
        printf "Ставим панель (y/n)?: ";
        read response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        printf "Установить бета-версию ISPmanager (y/N)? ";
        read response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        wget -O install.5.sh http://download.ispmanager.com/install.sh && sh install.5.sh --silent --ignore-hostname --release beta ispmanager-lite
        echo -ne "${LGREEN}Done${DEF}\n"
        else
        echo -ne "Устанавливаем стабильную версию ISPmanager"
        wget -O install.5.sh http://download.ispmanager.com/install.sh && sh install.5.sh
        echo -ne "${LGREEN}Done${DEF}\n"
        fi
        else
        echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
	return
        ;;
    5)
        echo -ne "\n"
        /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print $2}' | sed -s 's/name=//g'
	return
        ;;
    6)
        read -r -p "Do you really want it? (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            find /var/www/*/data/www/ -maxdepth 1 -type d | awk -F'/' '{print "chown -R "$4":"$4 " /var/www/"$4"/data/www/"}' | uniq | sh
            echo -ne "${LGREEN}Done${DEF}\n"
        else
            echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
	return
        ;;
    7)
        echo -ne "\n"
        echo "Откуда дигаем? : ";
        echo "1: ns1.firstvds.ru"
        echo "2: ns1.ispvds.com"
        echo "3: 8.8.8.8"
        echo "4: 1.1.1.1"
        read digserver

        case $digserver in
        1)
            digserver='ns1.firstvds.ru'
            ;;
        2)
            digserver='ns1.ispvds.com'
            ;;
        3)
            digserver='8.8.8.8'
            ;;     
        4)
            digserver='1.1.1.1'
            ;;
          esac
        echo 
        /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print $1}' | sed -s 's/name=//g' |while read line ; do echo "###"; echo -n $line " "; dig $line +short @$digserver | tail -n 1  ; done
        echo
        echo "digserver=$digserver ; /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print \$1}' | sed -s 's/name=//g' |while read line ; do echo \"###\"; echo -n \$line \" \"; dig \$line +short @\$digserver | tail -n 1  ; done"
        return
	;;
    *)
        echo -ne "${LRED}Unknown choose. Back to main menu${DEF}\n"
	return
	;;
    esac
  exit
}

BITRIX_MENU() {
  MENU() {
    echo -ne "\n"
    echo -ne "${LGREEN}\n BITRIX menu:\n${DEF}"
    echo -ne "\n"

    script_bitrix[1]='Скачать menu.sh'
    script_bitrix[2]='Настроить FTP'
    script_bitrix[3]='Скачать default конфиг Bitrix GT'
    script_bitrix[4]='Обход пароля в админку'
    script_bitrix[5]='Скачать скрипты для wildcard LE'
    script_bitrix[6]='Скачать restore.php'

    for index in ${!script_bitrix[*]}; do
      printf "%4d: %s\n" $index "${script_bitrix[$index]}"
    done
  }

MENU
    echo -ne "\n"
    read -r -p "Choose: " payload
    case $payload in
    0)
        return ;;
    1)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/admin.sh)
        return
	;;
    2)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/bitrix-env-ftp.sh)
	return
	;;
    3)
        wget http://rep.fvds.ru/cms/bitrixinstaller.tgz
        echo -ne "${LGREEN}Done${DEF}\\n"
	return
        ;;
    4)
        wget -q --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/pusti.txt
        mv pusti.txt pusti.php
        echo -ne "${LGREEN}Готоу. Скопируй файл pusti.php в корень сайта и перейди по ссылке https://example.com/pusti.php${DEF}\\n"
	return
        ;;
    5)
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook.sh -O /opt/lew_dnsmgr_hook.sh && chmod +x /opt/lew_dnsmgr_hook.sh
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook_del.sh -O /opt/lew_dnsmgr_hook_del.sh && chmod +x /opt/lew_dnsmgr_hook_del.sh
        echo -ne "\nКоманда для выпуска (в скрипте надо сменить доступы и путь до лога):\n"
        echo -ne "certbot certonly --manual --manual-public-ip-logging-ok --preferred-challenges=dns -d *.example.com -d example.com --manual-auth-hook /opt/lew_dnsmgr_hook.sh --manual-cleanup-hook /opt/lew_dnsmgr_hook_del.sh --dry-run\n"
        return
	;;
    6)
        wget http://www.1c-bitrix.ru/download/scripts/restore.php
        echo -ne "${LGREEN}Done${DEF}\\n"
	return
        ;;
    *)
        echo -ne "${LRED}Unknown choose. Back to main menu${DEF}\n"
	return
	;;
    esac
  exit
}

Debug() {
  MENU() {
    echo -ne "\n"
    echo -ne "${LGREEN}\n Debug menu:\n${DEF}"
    echo -ne "\n"

    script_debug[0]='Вернуться в меню'
    script_debug[1]='Посмотреть место'
    script_debug[2]='srv_info'
    script_debug[3]='Парсинг логов апача'
    script_debug[4]='Тест отправки почты'
    script_debug[5]='Тест скорости'

    for index in ${!script_debug[*]}; do
      printf "%4d: %s\n" $index "${script_debug[$index]}"
    done
  }

MENU
    echo -ne "\n"
    read -r -p "Choose: " payload
    case $payload in
    0)
        return
	;;
    1)
        bash <(wget -q -O- --no-check-certificate https://raw.githubusercontent.com/Vygoposha/tools.sh/refs/heads/main/du.sh)
	return
        ;;
    2)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/srv_info.sh)
	return
        ;;
    3)
        DATE=$(LANG=en_us_88591; date +%d/%b/%Y);
        printf "\nТоп-10 наиболее активных IP-адресов:\n";
        grep "$DATE" /var/www/httpd-logs/*.access.log  | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10;
        printf "\n";

        printf "Что с сайтов было запрошено: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | awk '{print $1" "$7}' | sort | uniq -c | sort -rnk1 | head -n 10;
        printf "\n";

        printf "Запросы файла xmlrpc.php: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | grep "xmlrpc" | awk '{print $1" "$7}' | tr -d \" | uniq -c | sort -rnk1 | head
        printf "\n";

        printf "TOP-10 ботов: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | cut -d" " -f 12 | sort | uniq -c | sort -rnk1 | head -n 10
        printf "\n";
	return
        ;;
    4)
        printf "\nКуда отправить?:\n";
        read -r -p '(echo -ne "Subject:Support"; echo "Hello! Please, dont reply to this email.";) | sendmail -v ' email 
        (echo "Subject:Support"; echo "Hello! Please, dont reply to this email.";) | sendmail -v $email
	return
	;;
    5)    
        python3 <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/speedtest-cli-custom-servers-msk)
	return
        ;;
    *)
        echo -ne "${LRED}Unknown choose. Back to main menu${DEF}\n" 
        return
        ;;
    esac
  exit
}

Tools() {
  MENU() {
    echo -ne "\n"
    echo -ne "${LGREEN}\n Tools menu:\n${DEF}"
    echo -ne "\n"

    script_tools[1]='Выполнить MTR'
    script_tools[2]='Выполнить strace'
    script_tools[3]='Запустить mysqltuner'
    script_tools[4]='Добавить ssh-ключики'
    script_tools[5]='Backup config'
    script_tools[6]='Скрипт IP change'
    script_tools[0]='Вернуться в меню'

    for index in ${!script_tools[*]}; do
      printf "%4d: %s\n" $index "${script_tools[$index]}"
    done
  }

MENU
    echo -ne "\n"
    read -r -p "Choose: " payload
    case $payload in
    0)
        return ;;
    1)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/mtr.sh)
	return
        ;;
    2)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/strace.sh)
	return
        ;;
    3)
        perl <(wget -q -O- https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl)
	return
        ;;
    4)
        bash <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/add_move_key.sh)
	return
        ;;
    5)
        if  [ -e /root/support/$(date  +%Y%m%d) ]; then
        printf "Копия уже есть. \n 1: Перезаписать \n 2: Мувнуть в /root/support/$(date  +%Y%m%d)_old и заново бэкапнуть \n";
        read STATE;
        if [ $STATE = "1" ] 
        then
        find /root/support/$(date  +%Y%m%d) -delete
        python3 <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup.py)
        if [ $? -ne 0 ]; then
        python <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup_py27.py)
        fi
        fi
        if [ $STATE = "2" ] 
        then
        mv /root/support/$(date  +%Y%m%d) /root/support/$(date  +%Y%m%d)_old
        python3 <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup.py)
        if [ $? -ne 0 ]; then
        python <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup_py27.py)
        fi
        fi
        else
        python3 <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup.py)
        if [ $? -ne 0 ]; then
        python <(wget -q -O- --no-check-certificate https://gitlab.hoztnode.net/szajcev/tools/-/raw/main/scripts/backup_py27.py)
        fi
        fi
	return
        ;;
    6)  
        wget --no-check-certificate https://gitlab.hoztnode.net/admins/scripts/-/raw/master/ip_change.sh
        echo -ne "${LGREEN}Готово. Не забудь сделать chmod +x${DEF}\n"
        ;;    
    *)
        echo -ne "${LRED}Unknown choose. Back to main menu${DEF}\n" 
        return
        ;;
    esac
  exit
}

#основа
while :
do
  MAIN_MENU
    echo -ne "\n"
    read -r -p "Choose: " payload
    case $payload in
    0)
      break ;;
    1)
      Debug
      ;;
    2)
      Tools
      ;;
    3)
      ISP_MENU 
      ;;
    4)
      BITRIX_MENU 
      ;;
    *)
	echo -ne "${LRED}Unknown choose${DEF}\n"
	;;
  esac
done
