#!/bin/bash

docker build -t injest-client-builder:latest .

GEM_VERSION=$(grep version injest.gemspec | awk '{ print $3 }' | sed 's/"//g')
echo "Running $1 with version ${GEM_VERSION}"

case $1 in

  build)
    docker run --rm -it \
      -w /gem \
      -v ${PWD}:/gem \
      -v ${HOME}/.gem/credentials:/root/.gem/credentials \
      injest-client-builder:latest sh -c "gem build && gem push injest-client-${GEM_VERSION}.gem"
    ;;

  *)
    docker run --rm -it \
      -v ${PWD}:/gem \
      -w /gem \
      -v ${HOME}/.gem/credentials:/root/.gem/credentials \
      injest-client-builder:latest bash
    ;;

esac
