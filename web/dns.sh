#!/bin/bash

#----------------------------------------------------
# File: dns.sh
# Contents: 私有域名解析dns服务, bind
# Date: 19-4-17
#----------------------------------------------------

version="9.14.0"
dir=$(pwd)
installdir=/opt/local/dns

cmd_exists() {
  cmd="$1"
  if [ -z "$cmd" ] ; then
    echo "Usage: cmd_exists cmd"
    return 1
  fi

  if type command >/dev/null 2>&1 ; then
    command -v ${cmd} >/dev/null 2>&1
  else
    type ${cmd} >/dev/null 2>&1
  fi

  ret="$?"
  return ${ret}
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

    if cmd_exists curl; then
        curl -o bind-${version}.tar.gz ${url}
    elif cmd_exists wget; then
        wget -o bind-${version}.tar.gz --no-check-certificate ${url}
    elif cmd_exists axel; then
        axel -n 10 -o bind-${version}.tar.gz ${url}
    else
        echo
        echo "Sorry, you must have curl or wget installed first."
        echo "Please install either of them and try again."
        echo
        exit
    fi

    tar -zvxf bind-${version}.tar.gz
}

install_depend() {
    apt-get update && \
    apt-get install gcc build-essential openssl libssl-dev perl libperl-dev libcap-dev -y
}

make_install() {
    rm -rf ${installdir} && mkdir -p ${installdir}

    cd ${dir}/bind-${version} &&
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

    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} && make install
}


bind_config() {
    # root
    cat > ${installdir}/etc/root <<-'EOF'
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

    # localhost
    cat > ${installdir}/etc/localhost <<-'EOF'
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

    # 127.arpa
    cat > ${installdir}/etc/127.arpa <<-'EOF'
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

    # 0.arpa
    cat > ${installdir}/etc/0.arpa <<-'EOF'
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

    # 255.arpa
    cat > ${installdir}/etc/255.arpa <<-'EOF'
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

    # default-zones.conf
    cat > ${installdir}/etc/default-zones.conf <<-'EOF'
// prime the server with knowledge of the root servers
zone "." {
	type hint;
	file "/opt/local/dns/etc/root";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
	type master;
	file "/opt/local/dns/etc/localhost";
};

zone "127.in-addr.arpa" {
	type master;
	file "/opt/local/dns/etc/127.arpa";
};

zone "0.in-addr.arpa" {
	type master;
	file "/opt/local/dns/etc/0.arpa";
};

zone "255.in-addr.arpa" {
	type master;
	file "/opt/local/dns/etc/255.arpa";
};
EOF

    # named.conf
    cat > ${installdir}/etc/named.conf <<-'EOF'
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { ::1; };

    directory "/opt/local/dns/var/named"; # server work dir
    pid-file  "/opt/local/dns/var/run/bind.pid"; # pid file
    statistics-file "stats.txt"; # default statistis info file
    memstatistics-file "memstats.txt";   # default memory used statistis file
    bindkeys-file "/opt/local/dns/etc/bind.keys";

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
include "/opt/local/dns/etc/default-zones.conf";
include "/opt/local/dns/var/named/*"
EOF
}

bind_service() {
    # 创建用户组并修改权限
    if [[ -z "$(cat /etc/group | grep -E '^bind:')" ]]; then
        groupadd -r bind
    fi

    if [[ -z "$(cat /etc/passwd | grep -E '^bind:')" ]]; then
        useradd -r bind -g bind
    fi

    cat > /etc/init.d/bind <<-'EOF'
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

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DIR=/opt/local/dns
PIDFILE=${DIR}/var/run/bind.pid

# for a chrooted server: "-u bind -t ${DIR}/lib/named"
# Don't modify this line, change or create /etc/default/bind.
OPTIONS="-u bind"
RESOLVCONF=no
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

    # 权限
    chmod a+x /etc/init.d/bind && \
    update-rc.d nginx defaults

    # 启动
    service bind start
}

do_install() {
    check_param

    if [[ ! -e ${dir}/bind-${version} ]]; then
        download_bind
    fi

    install_depend
    make_install
}

do_install