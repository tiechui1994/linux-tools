#!/bin/bash

#----------------------------------------------------
# File: upstart-service
# Contents: Upstart Service Config
# Date: 19-5-30
#----------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart Event State:
#
# waiting: initial state.
# starting: job is about to start.
# pre-start: running pre-start section.
# spawnded: about to run script or exec section.
# post-start: running post-start section.
# running: interim state set after post-start section processed denoting job is running(But it may have no associated PID!)
# pre-stop: running pre-stop section.
# stopping: interim(temp) state set after pre-stop section processed.
# killed: job is about to be stopped.
# post-stop: running post-stop section.
#
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# Upstart Job Config
#
# 任务支持的语法关键字
#
# - Process Definition:
# exec, script, pre-start, post-start, pre-stop, post-stop
#
# - Event Definition:
# start on, stop on, manual
#
# - Job Environment:
# env, export
#
# - Services, Tasks and Respawning:
# normal exit, respawn limit, task
#
# - Instances:
# instance
#
# - Documentation:
# description, author, version, emits, usage
#
# - Process Environment:
# console none, console log, console output, console owner, nice, chrooot, chdir, oom score, setuid,
# setgid, umask
#
# - Process Control:
# except fork, except daemon, except stop, kill signal, kill timeout
#
# - 过期关键字:
# service, daemon, pid
#
#
#
#
#
#
#
# 1
#---------------------------------------------------------------------------------------------------