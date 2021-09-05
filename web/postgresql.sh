#!/bin/sh

#=================================================================
# ubuntu16.04安装 postgresql
#==================================================================

declare -r version=10.5
declare -r workdir=$(pwd)
declare -r installdir=/opt/local/pgsql

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

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        log_error "Please use root privileges to execute"
        exit
    fi
}

download_psgl() {
    url="http://ftp.postgresql.org/pub/source/v$version/postgresql-$version.tar.gz"
    download "postgresql.tar.gz" ${url} axel 1
    return $?
}

build() {
    apt-get install zlib1g zlib1g-dev libedit-dev libperl-dev openssl libssl-dev \
        libxml2 libxml2-dev libxslt-dev bison tcl tcl-dev flex -y
    if [[ $? -ne 0 ]]; then
        log_error "install depend failed..."
        return ${failure}
    fi

    rm -rf ${installdir}
    cd ${workdir}/postgresql

    ./configure \
    --prefix=${installdir} \
    --with-tcl \
    --with-perl \
    --with-openssl \
    --without-readline \
    --with-libedit-preferred \
    --with-libxml \
    --with-libxslt
    if [[ $? -ne ${success} ]]; then
        log_error "configure failed..."
        return ${failure}
    fi

    # make and install
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j ${cpu}
    if [[ $? -ne 0 ]]; then
        log_error "configure failed..."
        return ${failure}
    fi

    make install
    if [[ $? -ne 0 ]]; then
        log_error "configure failed..."
        return ${failure}
    fi
}

add_service() {
    # user and group
    if [[ -z "$(cat /etc/group|grep -E '^postgre:')" ]]; then
       groupadd -r postgre
    fi
    if [[ -z "$(cat /etc/passwd|grep -E '^postgre:')" ]]; then
        useradd -r -g postgre -s /sbin/nologin postgre
    fi

    # dir
    mkdir -p ${installdir}/log && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/etc

    # update install dir owner
    chown -R postgre:postgre "$installdir"

    # conf
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

clean() {
    rm -rf ${workdir}/postgresql
    rm -rf ${workdir}/postgresql.tar.gz
}

do_instll() {
    check_user
    if [[ $? -ne ${success} ]]; then
        return
    fi

    download_psgl
    if [[ $? -ne ${success} ]]; then
        return
    fi

    build
    if [[ $? -ne ${success} ]]; then
        return
    fi

    add_service
    if [[ $? -ne ${success} ]]; then
        return
    fi

    clean
}

do_instll