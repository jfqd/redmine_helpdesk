#!/bin/bash

REDMINE_SOURCE_URL="http://www.redmine.org/releases"
REDMINE_NAME="redmine-${REDMINE_VERSION}"
REDMINE_PACKAGE="${REDMINE_NAME}.tar.gz"
REDMINE_URL="${REDMINE_SOURCE_URL}/${REDMINE_PACKAGE}"

version=(${REDMINE_VERSION//./ })
major=${version[0]}
minor=${version[1]}
patch=${version[2]}

GITHUB_SOURCE="${GITHUB_USER}/${GITHUB_PROJECT}"
PLUGIN_PATH=${PLUGIN_PATH:-$GITHUB_SOURCE}
PLUGIN_NAME=${PLUGIN_NAME:-$GITHUB_PROJECT}


function install_redmine() {
  log_title "GET TARBALL"
  wget "${REDMINE_URL}"
  log_ok

  log_title "EXTRACT IT"
  tar xf "${REDMINE_PACKAGE}"
  log_ok

  log_title "MOVE PLUGIN"
  # Move GITHUB_USER/GITHUB_PROJECT to redmine/plugins dir
  mv "${PLUGIN_PATH}" "${REDMINE_NAME}/plugins"
  # Remove parent dir (GITHUB_USER)
  rmdir $(dirname ${PLUGIN_PATH})
  log_ok

  log_title "CREATE SYMLINK"
  ln -s "${REDMINE_NAME}" "redmine"
  ln -s "redmine/plugins/${PLUGIN_NAME}/.git" "${REDMINE_NAME}/.git"
  log_ok

  log_title "INSTALL DATABASE FILE"
  if [ "$DATABASE_ADAPTER" == "mysql" ] ; then
    echo "Type : mysql"
    cp "redmine/plugins/${PLUGIN_NAME}/contrib/travis/database_mysql.yml" "redmine/config/database.yml"
  else
    echo "Type : postgres"
    cp "redmine/plugins/${PLUGIN_NAME}/contrib/travis/database_postgres.yml" "redmine/config/database.yml"
  fi

  log_ok
}

function finish_install() {
  log_header "CURRENT DIRECTORY LISTING"
  ls -l "${CURRENT_DIR}"
  echo ""

  log_header "REDMINE PLUGIN DIRECTORY LISTING"
  ls -l "${REDMINE_NAME}/plugins"
  echo ""
}
