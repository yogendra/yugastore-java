#!/usr/bin//env bash

set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=${SCRIPT_DIR}

TEMP_ROOT=${TEMP_ROOT:=/tmp/yugastore}


[[ -e $TEMP_ROOT ]] || mkdir -p $TEMP_ROOT

projects="eureka-server-local api-gateway-microservice cart-microservice products-microservice login-microservice checkout-microservice"

function do_with_all_projects () {
  OP=$1; shift
  for project in ${projects}
  do
    $OP $project $@
  done
}
function start() {
  do_with_all_projects start_project
}

function stop() {
  do_with_all_projects stop_project
}

function cleanup(){
  do_with_all_projects cleanup_project
}


function test() {
  project=$1; shift
  echo "Project: [${project}]"
  echo "Args: $@"
}

function start_project() {
  project=$1
  stdout=${TEMP_ROOT}/${project}.stdout.log
  stderr=${TEMP_ROOT}/${project}.stderr.log
  pid=${TEMP_ROOT}/${project}.pid

  if [[ -e ${pid} ]]; then
    echo "$project: Seems to be running"
    exit 1
  fi
  nohup ${PROJECT_DIR}/mvnw -pl ${project} spring-boot:run >${stdout} 2>${stderr} &
  echo $! >${pid}
  echo ${project}: Started

}

function stop_project() {
  project=$1; shift
  pid=${TEMP_ROOT}/${project}.pid
  if [[ -e ${pid} ]]; then
    kill $(cat ${pid})
    rm ${pid}
    echo ${project}: Stopped
  fi
}
function watch_project() {
  project=$1
  stdout=${TEMP_ROOT}/${project}.stdout.log
  stderr=${TEMP_ROOT}/${project}.stderr.log
  tail -f ${stdout} -f ${stderr}
}
function cleanup_project() {
  project=$1
  stdout=${TEMP_ROOT}/${project}.stdout.log
  stderr=${TEMP_ROOT}/${project}.stderr.log
  pid=${TEMP_ROOT}/${project}.pid
  stop_project $project
  rm ${stdout} ${stderr} ${pid} &>> /dev/null || true
}

function watch() {
  tail_args=""
  for project in ${projects}
  do
    stdout=${TEMP_ROOT}/${project}.stdout.log
    stderr=${TEMP_ROOT}/${project}.stderr.log
    tail_args="${tail_args} -f ${stdout} -f ${stderr}"
  done
  tail ${tail_args}
}

OP=start
if [[ $# -gt 0 ]] ; then
  OP=${1:-start}; shift
fi

$OP $@
