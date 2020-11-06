#!/bin/sh

#=================================================================
# ubuntu16.04安装 postgresql
#==================================================================

version=10.5
workdir=$(pwd)
installdir=/opt/local/pgsql

SUCCESS=0
DECOMPRESS_FAIL=1
DOWNLOAD_FAIL=2
CONFIGURE_FAIL=3
BUILD_FAIL=4
MAKE_FAIL=5
INSTALL_FAIL=6


# log
log_error(){
    red="\033[97;41m"
    reset="\033[0m"
    msg="[E] $@"
    echo -e "$red$msg$reset"
}
log_warn(){
    yellow="\033[90;43m"
    reset="\033[0m"
    msg="[W] $@"
    echo -e "$yellow$msg$reset"
}
log_info() {
    green="\033[97;42m"
    reset="\033[0m"
    msg="[I] $@"
    echo -e "$green$msg$reset"
}

common_download() {
    name=$1
    url=$2
    cmd=$3

    if [[ -d "$name" ]]; then
        log_info "$name has exist !!"
        return ${SUCCESS}
    fi

    if [[ -f "$name.tar.gz" && -n $(file "$name.tar.gz" |grep -o 'POSIX tar archive') ]]; then
        rm -rf ${name} && mkdir ${name}
        tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
        if [[ $? -ne 0 ]]; then
            log_error "$name decopress failed"
            rm -rf ${name}*
            return ${DECOMPRESS_FAIL}
        fi
        return ${SUCCESS}
    fi

    log_info "$name url: $url"
    rm -rf ${name}.tar.gz
    command_exists "$cmd"
    if [[ $? -eq 0 && "$cmd" == "axel" ]]; then
        axel -n 10 -o "$name.tar.gz" ${url}
    else
        curl -C - ${url} -o "$name.tar.gz"
    fi

    if [[ $? -ne 0 ]]; then
        log_error "$name source download failed"
        rm -rf ${name}.tar.gz
        return ${DOWNLOAD_FAIL}
    fi

    rm -rf ${name} && mkdir ${name}
    tar -zvxf ${name}.tar.gz -C ${name} --strip-components 1
    if [[ $? -ne 0 ]]; then
        log_error "$name decopress failed"
        rm -rf ${name}*
        return ${DECOMPRESS_FAIL}
    fi
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        log_error "Please use root privileges to execute"
        exit
    fi
}

download_psgl() {
    prefix=http://ftp.postgresql.org/pub/source
    url="$prefix/v$version/postgresql-$version.tar.gz"
    common_download "postgresql" ${url} axel
    return $?
}

build() {
    apt-get install zlib1g zlib1g-dev libedit-dev libperl-dev openssl libssl-dev \
        libxml2 libxml2-dev libxslt-dev bison tcl tcl-dev flex -y
    if [[ $? -ne 0 ]]; then
        log_error "install depend failed..."
        return ${INSTALL_FAIL}
    fi

    rm -rf ${installdir}
    cd ${workdir}/postgresql && \
    ./configure \
    --prefix=${installdir} \
    --with-tcl \
    --with-perl \
    --with-openssl \
    --without-readline \
    --with-libedit-preferred \
    --with-libxml \
    --with-libxslt
    if [[ $? -ne ${SUCCESS} ]]; then
        log_error "configure failed..."
        return ${CONFIGURE_FAIL}
    fi

    # make and install
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "configure failed..."
        return ${MAKE_FAIL}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "configure failed..."
        return ${INSTALL_FAIL}
    fi

    return ${SUCCESS}
}

add_service() {
    mkdir -p ${installdir}/log && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/etc

    read -r -d '' conf <<-'EOF'
#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = "$dir/data"
external_pid_file = "$dir/log/pgsql.pid"

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = 'localhost'
port = 5432
max_connections = 100
superuser_reserved_connections = 3
unix_socket_directories = "$dir/log"
unix_socket_permissions = 0777


#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

# - Memory -

shared_buffers = 128MB			# min 128kB
temp_buffers = 64MB			    # min 800kB
max_prepared_transactions = 500	# zero disables the feature

work_mem = 4MB				        # min 64kB
maintenance_work_mem = 64MB		    # min 1MB
replacement_sort_tuples = 150000    # limits use of replacement selection sort
autovacuum_work_mem = -1		    # min 1MB, or -1 to use maintenance_work_mem
max_stack_depth = 2MB			    # min 100kB
dynamic_shared_memory_type = posix	# the default is the first option
                                    # supported by the operating system:
                                    #   posix
                                    #   sysv
                                    #   windows
                                    #   mmap
                                    # use none to disable dynamic shared memory

# - Disk -

temp_file_limit = -1			    # limits per-process temp file space in kB, or -1 for no limit

# - Kernel Resource Usage -

max_files_per_process = 1000		# min 25

# - Background Writer -

bgwriter_delay = 100ms			    # 10-10000ms between rounds

# - Asynchronous Behavior -

max_worker_processes = 8
max_parallel_workers_per_gather = 2
max_parallel_workers = 8


#------------------------------------------------------------------------------
# WRITE AHEAD LOG
#------------------------------------------------------------------------------

# - Settings -

wal_level = replica			# minimal, replica, or logical
fsync = on				    # flush data to disk for crash safety
synchronous_commit = on	    # synchronization level; off, local, remote_write, remote_apply, or on

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------

# - Planner Method Configuration -

enable_bitmapscan = on
enable_hashagg = on
enable_hashjoin = on
enable_indexscan = on
enable_indexonlyscan = on
enable_material = on
enable_mergejoin = on
enable_nestloop = on
enable_seqscan = on
enable_sort = on
enable_tidscan = on

#------------------------------------------------------------------------------
# ERROR REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - Where to Log -

log_destination = 'stderr'		# Valid values are combinations of stderr, csvlog, syslog, and eventlog,
					            # depending on platform.

# These are only used if logging_collector is on:
log_directory = '/opt/local/pgsql/log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern, can include strftime() escapes
log_file_mode = 0600			                # creation mode for log files
log_truncate_on_rotation = on
log_rotation_age = 1d			# Automatic rotation of logfiles will happen after that time. 0 disables.
log_rotation_size = 10MB

# - When to Log -

client_min_messages = notice		# values in order of decreasing detail:
                                    #   debug5
                                    #   debug4
                                    #   debug3
                                    #   debug2
                                    #   debug1
                                    #   log
                                    #   notice
                                    #   warning
                                    #   error

log_min_messages = warning		# values in order of decreasing detail:
                                #   debug5
                                #   debug4
                                #   debug3
                                #   debug2
                                #   debug1
                                #   info
                                #   notice
                                #   warning
                                #   error
                                #   log
                                #   fatal
                                #   panic

log_min_error_statement = error	# valuse same as log_min_messages


# - What to Log -

debug_print_parse = off
debug_print_rewritten = off
debug_print_plan = off
debug_pretty_print = on
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = off
log_error_verbosity = default		# terse, default, or verbose messages
log_hostname = off
log_line_prefix = '%m [%p] '		# special values:
					#   %a = application name
					#   %u = user name
					#   %d = database name
					#   %r = remote host and port
					#   %h = remote host
					#   %p = process ID
					#   %t = timestamp without milliseconds
					#   %m = timestamp with milliseconds
					#   %n = timestamp with milliseconds (as a Unix epoch)
					#   %i = command tag
					#   %e = SQL state
					#   %c = session ID
					#   %l = session line number
					#   %s = session start timestamp
					#   %v = virtual transaction ID
					#   %x = transaction ID (0 if none)
					#   %q = stop here in non-session processes
					#   %% = '%'
					# e.g. '<%u%%%d> '

log_timezone = 'GMT'
EOF

    regex='$dir'
    repl="$installdir"
    printf "%s" "${conf//$regex/$repl}" > ${installdir}/etc/pgsql.conf
}

do_instll() {
    check_user
    download_psgl
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    build
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${SUCCESS} ]]; then
        return
    fi
}

do_instll