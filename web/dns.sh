#!/bin/bash

#----------------------------------------------------
# File: dns.sh
# Contents: 私有域名解析dns服务, bind
# Date: 19-4-17
#----------------------------------------------------

version="9.14.0"
workdir=$(pwd)
installdir=/opt/local/dns

declare -r success=0
declare -r failure=1

# log
log_error(){
    red="\033[31;1m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[33;1m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[32;1m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

download() {
    name=$1
    url=$2
    cmd=$3
    decompress=$4

    declare -A extends=(
        ["tar"]="application/x-tar"
        ["tgz"]="application/gzip"
        ["tar.gz"]="application/gzip"
        ["tar.bz2"]="application/x-bzip2"
        ["tar.xz"]="application/x-xz"
    )

    extend="${name##*.}"
    filename="${name%%.*}"
    temp=${name%.*}
    if [[ ${temp##*.} = "tar" ]]; then
         extend="${temp##*.}.${extend}"
         filename="${temp%%.*}"
    fi

    # uncompress file
    if [[ -f "$name" ]]; then
        if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
            rm -rf ${filename} && mkdir ${filename}
            tar -xf ${name} -C ${filename} --strip-components 1
            if [[ $? -ne 0 ]]; then
                log_error "$name decopress failed"
                rm -rf ${filename} && rm -rf ${name}
                return ${failure}
            fi
        fi

        return ${success} #2
    fi

    # download
    log_info "$name url: $url"
    log_info "begin to donwload $name ...."
    rm -rf ${name}

    command -v "$cmd" > /dev/null 2>&1
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 --insecure --quite -o ${name} ${url}
    else
        curl -C - --insecure  --silent --location -o ${name} ${url}
    fi
    if [[ $? -ne 0 ]]; then
        log_error "download file $name failed !!"
        rm -rf ${name}
        return ${failure}
    fi

    log_info "success to download $name"

    # uncompress file
    if [[ ${decompress} && ${extends[$extend]} && $(file -i "$name") =~ ${extends[$extend]} ]]; then
        rm -rf ${filename} && mkdir ${filename}
        tar -xf ${name} -C ${filename} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${filename} && rm -rf ${name}
            return ${failure}
        fi

        return ${success} #2
    fi
}

check_param() {
    if [[ "$(whoami)" != "root" ]]; then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_bind() {
    url="https://www.isc.org/downloads/file/bind-9-14-0/?version=tar-gz"
    download "bind.tar.gz" ${url} curl 1
    return $?
}

build() {
    apt-get update && \
    apt-get install resolvconf net-tools gcc build-essential openssl libssl-dev \
    perl libperl-dev libcap-dev -y

    rm -rf ${installdir}
    cd ${workdir}/bind

    ./configure \
    --prefix=${installdir} \
    --exec-prefix=${installdir} \
    --sysconfdir=${installdir}/etc \
    --mandir=${installdir}/man \
    --enable-symtable \
    --enable-backtrace \
    --enable-largefile \
    --enable-epoll \
    --enable-dnsrps \
    --enable-full-report \
    --enable-threads \
    --with-libtool \
    --with-python \
    --with-openssl
    if [[ $? -ne 0 ]]; then
        log_error "configure fail, plaease check and try again.."
        return ${failure}
    fi

    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "make fail, plaease check and try again..."
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "make install fail, plaease check and try again..."
        return ${failure}
    fi
}

add_config() {
    # root
    read -r -d '' conf <<- 'EOF'
;       This file holds the information on root name servers needed to
;       initialize cache of Internet domain name servers
;       (e.g. reference this file in the "cache  .  <file>"
;       configuration file of BIND domain name servers).
;
;       This file is made available by InterNIC
;       under anonymous FTP as
;           file                /domain/named.cache
;           on server           FTP.INTERNIC.NET
;       -OR-                    RS.INTERNIC.NET
;
;       last update:    February 17, 2016
;       related version of root zone:   2016021701
;
; formerly NS.INTERNIC.NET
;
.                        3600000      NS    A.ROOT-SERVERS.NET.
A.ROOT-SERVERS.NET.      3600000      A     198.41.0.4
A.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:ba3e::2:30
;
; FORMERLY NS1.ISI.EDU
;
.                        3600000      NS    B.ROOT-SERVERS.NET.
B.ROOT-SERVERS.NET.      3600000      A     192.228.79.201
B.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:84::b
;
; FORMERLY C.PSI.NET
;
.                        3600000      NS    C.ROOT-SERVERS.NET.
C.ROOT-SERVERS.NET.      3600000      A     192.33.4.12
C.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2::c
;
; FORMERLY TERP.UMD.EDU
;
.                        3600000      NS    D.ROOT-SERVERS.NET.
D.ROOT-SERVERS.NET.      3600000      A     199.7.91.13
D.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2d::d
;
; FORMERLY NS.NASA.GOV
;
.                        3600000      NS    E.ROOT-SERVERS.NET.
E.ROOT-SERVERS.NET.      3600000      A     192.203.230.10
;
; FORMERLY NS.ISC.ORG
;
.                        3600000      NS    F.ROOT-SERVERS.NET.
F.ROOT-SERVERS.NET.      3600000      A     192.5.5.241
F.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2f::f
;
; FORMERLY NS.NIC.DDN.MIL
;
.                        3600000      NS    G.ROOT-SERVERS.NET.
G.ROOT-SERVERS.NET.      3600000      A     192.112.36.4
;
; FORMERLY AOS.ARL.ARMY.MIL
;
.                        3600000      NS    H.ROOT-SERVERS.NET.
H.ROOT-SERVERS.NET.      3600000      A     198.97.190.53
H.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:1::53
;
; FORMERLY NIC.NORDU.NET
;
.                        3600000      NS    I.ROOT-SERVERS.NET.
I.ROOT-SERVERS.NET.      3600000      A     192.36.148.17
I.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fe::53
;
; OPERATED BY VERISIGN, INC.
;
.                        3600000      NS    J.ROOT-SERVERS.NET.
J.ROOT-SERVERS.NET.      3600000      A     192.58.128.30
J.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:c27::2:30
;
; OPERATED BY RIPE NCC
;
.                        3600000      NS    K.ROOT-SERVERS.NET.
K.ROOT-SERVERS.NET.      3600000      A     193.0.14.129
K.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fd::1
;
; OPERATED BY ICANN
;
.                        3600000      NS    L.ROOT-SERVERS.NET.
L.ROOT-SERVERS.NET.      3600000      A     199.7.83.42
L.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:3::42
;
; OPERATED BY WIDE
;
.                        3600000      NS    M.ROOT-SERVERS.NET.
M.ROOT-SERVERS.NET.      3600000      A     202.12.27.33
M.ROOT-SERVERS.NET.      3600000      AAAA  2001:dc3::35
; End of file
EOF
    printf "%s" "${conf}" > ${installdir}/etc/root

    # localhost
    read -r -d '' conf <<- 'EOF'
;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	localhost. root.localhost. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	localhost.
@	IN	A	127.0.0.1
@	IN	AAAA	::1
EOF
    printf "%s" "${conf}" > ${installdir}/etc/localhost

    # 127.arpa
    read -r -d '' conf <<- 'EOF'
;
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	localhost. root.localhost. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	localhost.
1.0.0	IN	PTR	localhost.
EOF
    printf "%s" "${conf}" > ${installdir}/etc/127.arpa

    # 0.arpa
    read -r -d '' conf <<- 'EOF'
;
; BIND reverse data file for broadcast zone
;
$TTL	604800
@	IN	SOA	localhost. root.localhost. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	localhost.
EOF
    printf "%s" "${conf}" > ${installdir}/etc/0.arpa

    # 255.arpa
    read -r -d '' conf <<- 'EOF'
;
; BIND reverse data file for broadcast zone
;
$TTL	604800
@	IN	SOA	localhost. root.localhost. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	localhost.
EOF
    printf "%s" "${conf}" > ${installdir}/etc/255.arpa

    # default-zones.conf
    read -r -d '' conf <<- 'EOF'
// prime the server with knowledge of the root servers
zone "." {
	type hint;
	file "$dir/etc/root";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
	type master;
	file "$dir/etc/localhost";
};

zone "127.in-addr.arpa" {
	type master;
	file "$dir/etc/127.arpa";
};

zone "0.in-addr.arpa" {
	type master;
	file "$dir/etc/0.arpa";
};

zone "255.in-addr.arpa" {
	type master;
	file "$dir/etc/255.arpa";
};
EOF
    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/etc/default-zones.conf

    # named.conf
    read -r -d '' conf <<- 'EOF'
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { ::1; };

    directory "$dir/var/named"; # server work dir
    pid-file  "$dir/var/run/bind.pid"; # pid file
    statistics-file "stats.txt"; # default statistis info file
    memstatistics-file "memstats.txt";   # default memory used statistis file
    bindkeys-file "$dir/etc/bind.keys";

    allow-query { any; };       # the host where can query dns
    allow-query-cache { any; }; # the host where can query cached dns
    recursion yes;              # query recursion

    dnssec-enable yes;
    dnssce-validation yes;
    dnssec-lookaside auto;

    forward only;
    forwarders {
        8.8.8.8;
        8.4.8.4;
    };
};

logging {
    category default   { default_syslog; default_debug; };
    category unmatched { null; };

    channel default_syslog {
        syslog daemon;            // send to syslog's daemon facility
        severity info;            // only send priority info and higher
    };

    channel default_debug {
        file "named.log";         // write to named.run in the working directory
                                  // Note: stderr is used instead of "named.run"
                                  // if the server is started with the '-f' option.
        severity dynamic;         // log at the server's current debug level
    };

    channel default_stderr {
        stderr;                   // writes to stderr
        severity info;            // only send priority info and higher
    };

    channel null {
        null;                     // toss anything sent to this channel
    };
};

include "/etc/named.root.key";
include "$dir/etc/default-zones.conf";
EOF
    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/etc/named.conf
}

add_service() {
    # user and group
    if [[ -z "$(cat /etc/group | grep -E '^bind:')" ]]; then
        groupadd -r bind
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^bind:')" ]]; then
        useradd -r bind -g bind
    fi

    chown -R bind:bind ${installdir}

    read -r -d '' conf <<- 'EOF'
#!/bin/sh -e

### BEGIN INIT INFO
# Provides:          bind
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $network $syslog
# Should-Stop:       $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start and stop bind
### END INIT INFO

DIR=$dir
PIDFILE=${DIR}/var/run/bind.pid
CONF=${DIR}/etc/named.conf

# for a chrooted server: "-u bind -t ${DIR}/lib/named"
# Don't modify this line, change or create /etc/default/bind.
OPTIONS="-u bind -c ${CONF}"
RESOLVCONF=yes
test -f /etc/default/bind && . /etc/default/bind

test -x ${DIR}/sbin/rndc || exit 0

. /lib/lsb/init-functions


check_network() {
    if [ -x /usr/bin/uname ] && [ "X$(/usr/bin/uname -o)" = XSolaris ]; then
	    IFCONFIG_OPTS="-au"
    else
	    IFCONFIG_OPTS=""
    fi

    if [ -z "$(/sbin/ifconfig $IFCONFIG_OPTS)" ]; then
       # log_action_msg "No networks configured."
       return 1
    fi

    return 0
}

case "$1" in
    start)
	    log_daemon_msg "Starting domain name service..." "bind"

	    modprobe capability >/dev/null 2>&1 || true

        # dirs under ${DIR}/var/run can go away on reboots.
        mkdir -p ${DIR}/var/run
        chmod 775 ${DIR}/var/run
        chown root:bind ${DIR}/var/run >/dev/null 2>&1 || true

        if [ ! -x ${DIR}/sbin/named ]; then
            log_action_msg "named binary missing - not starting"
            log_end_msg 1
        fi

        if ! check_network; then
            log_action_msg "no networks configured"
            log_end_msg 1
        fi

        if start-stop-daemon --start --oknodo --quiet --exec ${DIR}/sbin/named \
            --pidfile ${PIDFILE} -- $OPTIONS; then
            if [ "X$RESOLVCONF" != "Xno" ] && [ -x /sbin/resolvconf ] ; then
                echo "nameserver 127.0.0.1" | /sbin/resolvconf -a lo.named
            fi
            log_end_msg 0
        else
            log_end_msg 1
        fi
        ;;

    stop)
        log_daemon_msg "Stopping domain name service..." "bind"
        if ! check_network; then
            log_action_msg "no networks configured"
            log_end_msg 1
        fi

        if [ "X$RESOLVCONF" != "Xno" ] && [ -x /sbin/resolvconf ] ; then
            /sbin/resolvconf -d lo.named
        fi

	    pid=$(${DIR}/sbin/rndc stop -p | awk '/^pid:/ {print $2}') || true

	    # no pid found, so either not running, or error
        if [ -z "$pid" ]; then
            pid=$(pgrep -f ^/usr/sbin/named) || true
            start-stop-daemon --stop --oknodo --quiet --exec ${DIR}/sbin/named \
                --pidfile ${PIDFILE} -- $OPTIONS
        fi

        if [ -n "$pid" ]; then
            sig=0
            n=1
            while kill -$sig $pid 2>/dev/null; do
                if [ $n -eq 1 ]; then
                    echo "waiting for pid $pid to die"
                fi
                if [ $n -eq 11 ]; then
                    echo "giving up on pid $pid with kill -0; trying -9"
                    sig=9
                fi
                if [ $n -gt 20 ]; then
                    echo "giving up on pid $pid"
                    break
                fi
                n=$(($n+1))
                sleep 1
            done
        fi

	    log_end_msg 0
        ;;

    reload|force-reload)
        log_daemon_msg "Reloading domain name service..." "bind9"
        if ! check_network; then
            log_action_msg "no networks configured"
            log_end_msg 1
        fi

        ${DIR}/sbin/rndc reload >/dev/null && log_end_msg 0 || log_end_msg 1
        ;;

    restart)
        if ! check_network; then
            log_action_msg "no networks configured"
            exit 1
        fi

        $0 stop
        $0 start
        ;;

    status)
    	ret=0
        status_of_proc -p ${PIDFILE} ${DIR}/sbin/named bind 2>/dev/null || ret=$?
        exit $ret
        ;;

    *)
        log_action_msg "Usage: /etc/init.d/bind {start|stop|reload|restart|force-reload|status}"
        exit 1
        ;;
esac

exit 0
EOF
    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > /etc/init.d/bind

    # service
    chmod a+x /etc/init.d/bind && update-rc.d nginx defaults
    if [[ $? -ne 0 ]]; then
        log_error "update-rc failed"
        return ${failure}
    fi

    # start
    service bind start
    if [[ $? -ne 0 ]]; then
        log_error "service start nginx failed"
        return ${failure}
    fi

    # test
    if [[ $(pgrep nginx) ]]; then
        log_info "nginx install successfully !"
        return ${success}
    fi

    return ${failure}
}

clean() {
    rm -rf ${workdir}/nginx
    rm -rf ${workdir}/nginx.tar.gz
}

do_install() {
    check_param
    if [[ $? -ne ${success} ]]; then
        return
    fi

    download_bind
    if [[ $? -ne ${success} ]]; then
        return
    fi

    build
    if [[ $? -ne ${success} ]]; then
        return
    fi

    add_config
    if [[ $? -ne ${success} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean
}

do_install