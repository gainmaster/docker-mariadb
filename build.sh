#!/usr/bin/env bash

# exit codes
# 1 - Version don't exist
# 2 - Docker image not built
# 3 - Missing binaries
# 4 - Missing docker credentials

trap 'exit 1' ERR   # Exit script with error if command fails

if [[ -z $(which docker) ]]; then
    echo "Missing docker client which is required for building, testing and pushing"
    exit 3
fi

declare PROJECT_DIRECTORY=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
declare DOCKER_IMAGE_NAME="gainmaster/mariadb"
declare VERSION_DIRECTORY="${PROJECT_DIRECTORY}/version"

cd ${PROJECT_DIRECTORY}

function pre_build() 
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't run pre-build functions on ${version}, the version don't exist"
        exit 1
    fi

    if [ "version" == "mariadb" ]; then
        cd ${PROJECT_DIRECTORY}/${VERSION_DIRECTORY}/{version}
        ${PROJECT_DIRECTORY}/utility/galera-builder.sh
        ${PROJECT_DIRECTORY}/utility/mariadb-galera-builder.sh
        cd ${PROJECT_DIRECTORY}
    fi
}


function build() 
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't build docker image ${DOCKER_IMAGE_NAME}:${version}, the version don't exist"
        exit 1
    fi

    while read tag; do
        docker build -t ${DOCKER_IMAGE_NAME}:${tag} ${directory}
    done < "${directory}/tags"
}

function post_build() 
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't run post-build functions on ${version}, the version don't exist"
        exit 1
    fi

    if [ "version" == "mariadb" ]; then
        rm -f ${PROJECT_DIRECTORY}/${VERSION_DIRECTORY}/{version}/galera.pkg.tar.xz
        rm -f ${PROJECT_DIRECTORY}/${VERSION_DIRECTORY}/{version}/mariadb-galera.pkg.tar.xz
    fi
}

function test()
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't run tests on ${DOCKER_IMAGE_NAME}:${version}, the version don't exist"
        exit 1
    fi

    docker history "${DOCKER_IMAGE_NAME}:${version}" 2> /dev/null

    if [ $? -eq 1 ]; then
        echo "Cant test ${DOCKER_IMAGE_NAME}:${version}, the image is not built"
        exit 2
    fi

    #bats /test/${version}.bats
}

function run()
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't run tests on ${DOCKER_IMAGE_NAME}:${version}, the version don't exist"
        exit 1
    fi

    docker history "${DOCKER_IMAGE_NAME}:${version}" 2> /dev/null

    if [ $? -eq 1 ]; then
        echo "Cant run ${DOCKER_IMAGE_NAME}:${version}, the image is not built"
        exit 2
    fi

    docker run -it --rm ${DOCKER_IMAGE_NAME}:${version} bash
}

function commit()
{
    version=${1}
    directory=${VERSION_DIRECTORY}/${version}

    if [ ! "${directory}" ]; then
        echo "Can't run tests on ${DOCKER_IMAGE_NAME}:${version}, the version don't exist"
        exit 1
    fi

    docker history "${DOCKER_IMAGE_NAME}:${version}" 2> /dev/null

    if [ $? -eq 1 ]; then
        echo "Cant push ${DOCKER_IMAGE_NAME}:${version}, the image is not built"
        exit 2
    fi

    [ -z "${DOCKER_EMAIL}" ]    && { echo "Need to set DOCKER_EMAIL";    exit 4; }
    [ -z "${DOCKER_USER}" ]     && { echo "Need to set DOCKER_USER";     exit 4; }
    [ -z "${DOCKER_PASSWORD}" ] && { echo "Need to set DOCKER_PASSWORD"; exit 4; }

    if [[ $EUID -ne 0 ]]; then
        if [[ -z $(which sudo) ]]; then
            echo "Missing sudo which is required for pushing when not root"
            exit 2
        fi

        sudo docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}

    else
        docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}
    fi


    while read tag; do
        if [[ $EUID -ne 0 ]]; then
            sudo docker push ${DOCKER_IMAGE_NAME}:${tag}
        else
            docker push ${DOCKER_IMAGE_NAME}:${tag}
        fi
    done < "${directory}/tags"
}


#
# Handle arguments
#

## Load versions
versions=()
while getopts "v: --long version:" opt; do
    case "$1" in
        --version)
            case "$2" in
                "")  echo "Option --version expected a argument" ; exit 5 ;;
                *) versions+=("${2}"); shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Option $1 is not valid!"; exit 1 ;;
    esac
done

if [ ${#versions[@]} -eq 0 ]; then
    for version in ${VERSION_DIRECTORY}/*; do
        versions+=($(basename $(echo $version)))
    done
fi

## Execute actions
shift $((OPTIND-1))
actions=("$@")

if [ ${#actions[@]} -eq 0 ]; then
    actions=(pre-build build post-build test commit)
fi

for action in "${actions[@]}"; do 
    case "$action" in
        pre-build)
            echo "Executing pre-build action"
            for version in "${versions[@]}"; do
                pre_build $version
            done
            ;;

        build)
            echo "Executing build action"
            for version in "${versions[@]}"; do
                build $version
            done
            ;;
        
        post-build)
            echo "Executing post-build action"
            for version in "${versions[@]}"; do
                post_build $version
            done
            ;;

        test)
            echo "Executing test action"
            for version in "${versions[@]}"; do
                test $version
            done
            ;;

        run)
            echo "Executing run action"
            for version in "${versions[@]}"; do
                run $version
            done
            ;;

        commit)
            echo "Executing push action"
            for version in "${versions[@]}"; do
                commit $version
            done
            ;;

        --*) break ;;

        *) echo "Ignoring invalid action ${action}" ;;
    esac
done