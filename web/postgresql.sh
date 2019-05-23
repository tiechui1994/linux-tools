#!/bin/sh

#=================================================================
# ubuntu16.04安装 postgresql
#==================================================================

version=10.5
installdir=/opt/local/pgsql

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_user() {
    if [[ "$(whoami)" != "root" ]];then
        echo
        echo "ERROR: Please use root privileges to execute"
        echo
        exit
    fi
}

download_postgre() {
    if ! command_exists axel; then
        apt-get update && apt-get install axel -y
    fi

    doamin=http://ftp.postgresql.org/pub/source
    axel -n 100 -o postgresql.tar.gz "${doamin}/v${version}/postgresql-${version}.tar.gz"

    [ -d postgresql ] || mkdir postgresql
    tar -zvxf postgresql.tar.gz -C postgresql --strip-components 1
}

install_depend() {
    apt-get install zlib1g zlib1g-dev libedit-dev libperl-dev openssl libssl-dev \
        libxml2 libxml2-dev libxslt-dev bison tcl tcl-dev flex -y
}

install() {
    rm -rf ${installdir}
    cd postgresql && \
    ./configure \
    --prefix=${installdir} \
    --with-tcl \
    --with-perl \
    --with-openssl \
    --without-readline \
    --with-libedit-preferred \
    --with-libxml \
    --with-libxslt

    # make and install
    cpu=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    make -j${cpu} &&  make install
}

add_config() {
    mkdir -p ${installdir}/log && \
    mkdir -p ${installdir}/data && \
    mkdir -p ${installdir}/etc && \
    cat >> ${installdir}/etc/pgsql.conf << EOF
#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = "/opt/local/pgsql/data"
external_pid_file = "/opt/local/pgsql/log/pgsql.pid"

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = 'localhost'
port = 5432
max_connections = 100
superuser_reserved_connections = 3
unix_socket_directories = '/opt/local/pgsql/log'
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
}

do_instll() {
    check_user
    download_postgre
    install_depend
    install
    add_config
}

do_instll