#!/bin/bash
set -e

# Requirements:
# - dpkg --add-architecture i386
# - apt-get update
# - apt-get install lib32gcc1

# TODO:
# - Renice Server process
# - check port reservations

# Empty == default port (27015)
SERVER_PORT="27030"
MAXPLAYERS="10"

APP_ID="740"
GAME="csgo"

GAME_TYPE="0"
GAME_MODE="1"

TICKRATE="128"

# Default startparameter
START_PARAM_DEFAULT="-pidfile srcds.pid -console -usercon -nobots -game $GAME +hostport $SERVER_PORT -tickrate $TICKRATE +maxplayers $MAXPLAYERS"

# DONT CHANGE ANYTHING FROM HERE #
if [ ! -z "$2" ]; then
  GAME_ROOT="$2"
  TMUX_SESSION_NAME=$(basename $GAME_ROOT)
else
  SCRIPT_PATH=$(readlink -f $0)
  GAME_ROOT=$(dirname $SCRIPT_PATH)
  TMUX_SESSION_NAME=${GAME_ROOT##*/}
fi

# SteamCMD
STEAMCMD_DIR="${GAME_ROOT}/steamcmd"
STEAMCMD_URL="http://media.steampowered.com/installer/steamcmd_linux.tar.gz"

function install_steamcmd() {
  if [ ! -d "$STEAMCMD_DIR" ]; then
    wget $STEAMCMD_URL -P $GAME_ROOT --quiet
    STEAMCMD_TAR="${GAME_ROOT}/steamcmd_linux.tar.gz"
    mkdir -p $STEAMCMD_DIR
    tar -xzf $STEAMCMD_TAR -C $STEAMCMD_DIR
    rm -f $STEAMCMD_TAR
    $STEAMCMD_DIR/steamcmd.sh +quit
  fi
}

function update_app() {
  STEAMCMD_LOGIN="+login anonymous"
  STEAMCMD_INSTALL_DIR="+force_install_dir ${GAME_ROOT}"
  STEAMCMD_APP_UPDATE="+app_update ${APP_ID} validate"
  $STEAMCMD_DIR/steamcmd.sh $STEAMCMD_LOGIN $STEAMCMD_INSTALL_DIR $STEAMCMD_APP_UPDATE +quit
}

function initalization() {
  SERVER_CFG="${GAME_ROOT}/csgo/cfg/server.cfg"
  touch $SERVER_CFG
  echo "hostname \"${TMUX_SESSION_NAME} by nerdran.ch\"" >> $SERVER_CFG

  # fill server.cfg with default options
  # rename gamemodes_linux.text.example
}

function start() {
  echo -n "Staring server ${TMUX_SESSION_NAME}..."
  START_PARAM_MAP="+map de_dust2"
  START_PARAM_GAMETYPE="+game_type $GAME_TYPE +game_mode $GAME_MODE"
  tmux new-session -d -s $TMUX_SESSION_NAME "${GAME_ROOT}/srcds_run $START_PARAM_DEFAULT $START_PARAM_MAP $START_PARAM_GAMETYPE" 2> /dev/null || (echo "FAILED"; exit -1)
  echo "OK"
}

function stop() {
  echo -n "Stopping server ${TMUX_SESSION_NAME}..."
  tmux kill-session -t $TMUX_SESSION_NAME 2> /dev/null || (echo "FAILED"; exit -1)
  echo "OK"
}

function status() {
  echo -n "Server is "
  tmux has-session -t $TMUX_SESSION_NAME 2> /dev/null || (echo "STOPPED"; exit -1)
  echo "running"
  #kill -0 $(cat ${GAME_ROOT/csgo/srcds.pid})
}

function console() {
  tmux attach -t $TMUX_SESSION_NAME 2> /dev/null || (echo "Server is STOPPED"; exit -1)
}

function info() {
  SERVERNAME=`cat ${GAME_ROOT}/csgo/cfg/server.cfg | grep hostname`
  SERVERNAME_FILTERED=${SERVERNAME##*hostname}

  case "${GAME_TYPE}${GAME_MODE}" in
    00)
      GAMEMODE="Classic Casual"
    ;;

    01)
      GAMEMODE="Classic Competetive"
    ;;

    12)
      GAMEMODE="Deathmatch"
    ;;

    10)
      GAMEMODE="Arms Race"
    ;;

    11)
      GAMEMODE="Demolition"
    ;;

    *)
      echo "unknown"
    ;;
  esac

  echo "Summary from ${TMUX_SESSION_NAME}:"
  echo "Servername: $SERVERNAME_FILTERED"
  echo "Game: ${GAME} (${APP_ID})"
  echo "Port: ${SERVER_PORT}"
  echo "Tickrate: ${TICKRATE}"
  echo "Gamemode: ${GAMEMODE}"
}

function usage() {
  echo "Usage: ./steam.sh {start|stop|restart|status|console|info|install} [install directory]"
}

case "$1" in
  install)
    install_steamcmd
    update_app
    initalization
  ;;

  installsteam)
    install_steamcmd
  ;;

  start)
    update_app
    start
  ;;

  stop)
    stop
  ;;

  restart)
    stop
    update_app
    start
  ;;

  status)
    status
  ;;

  console)
    console
  ;;

  info)
    info
  ;;

  *)
    usage
  ;;
esac
