#!/bin/sh

# loop forever but wait $GIT_CHECK_EACH_NBMINUTES between each loops 
while true
do

  # this script logs to this file so each time a new loop begins
  # we start with the date of the execution
  date > /tmp/create-htmlreport.periodically.log.html

  if [ ! -d /archi-model-git-repo/ ]; then
    echo "-> Git clone of archimatetool model repository: $GIT_REPOSITORY"
    git clone --depth 1 $GIT_REPOSITORY /archi-model-git-repo/
    cd /archi-model-git-repo/
    GIT_HASH_OLD=$(git rev-parse HEAD)
  else
    echo "-> Git pull archimatetool model repository: $GIT_REPOSITORY"
    cd /archi-model-git-repo/
    git checkout -q master
    git fetch origin && git reset --hard origin/master
    GIT_HASH_NEW=$(git rev-parse HEAD)
  fi

  if [ "$GIT_HASH_OLD" != "$GIT_HASH_NEW" ]; then
    cd /archi-model-git-repo/
    mkdir -p /usr/share/nginx/html-tmp/ && rm -rf /usr/share/nginx/html-tmp/*

    if [ -f ./create-htmlreport.prescript.sh ]; then
      echo "-> Running the create-htmlreport.prescript.sh script."
      chmod +x ./create-htmlreport.prescript.sh
      ./create-htmlreport.prescript.sh
    fi

    echo "-> Generating HTML report from the archimatetool model."
    xvfb-run /Archi/Archi -consoleLog -nosplash \
      -application com.archimatetool.commandline.app \
      --modelrepository.loadModel /archi-model-git-repo/ \
      -saveModel /archi-model-git-repo/model.archimate \
      --html.createReport /usr/share/nginx/html-tmp

    if [ -f ./create-htmlreport.postscript.sh ]; then
      echo "-> Running the create-htmlreport.postscript.sh script."
      chmod +x ./create-htmlreport.postscript.sh
      ./create-htmlreport.postscript.sh
    fi

    rm -rf /usr/share/nginx/html && mv /usr/share/nginx/html-tmp /usr/share/nginx/html
    echo "-> HTML report generated!"

    GIT_HASH_OLD=$GIT_HASH_NEW
  else
    echo "-> No change on git, skip the HTML report."
  fi

  echo "-> Waiting $GIT_CHECK_EACH_NBMINUTES minutes before next model check."
  # push few info to the web folder: version.html and create-htmlreport.periodically.log.html
  cp -f /version.html /usr/share/nginx/html/
  cp -f /tmp/create-htmlreport.periodically.log.html /usr/share/nginx/html/
  # and sleep
  sleep ${GIT_CHECK_EACH_NBMINUTES}m

done

