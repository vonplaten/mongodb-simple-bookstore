#!/bin/bash

: '
This shellscript show the commands that was made to build the a prototyp document database in Mongodb.
The prototype was made for a project at course database 2 at Uppsala Universitet.

The script creates a prototype mongodb instance in docker and fills it with bookstore data.

Arguments:
"server" - creates the mongodb server and creates users.
"data" - fill db with data from json files in ./collections/ folder and dump data to ./collections/out/

Commands to access the "mongodb instance" and the "mongodb shell" (interactive mode):
docker exec -it mymongo bash
mongo localhost:27017/bookstore

To access the mongodb shell directly from console in interactive mode the mongo package needs to 
be installed in the console.
I used WSL Ubuntu ZSH as shell and therefore installed with "sudo apt install mongodb-org-shell".  
The other packages from mongodb is not nessesary for access to mongo and I prefer not to have the 
server packages in my client devenvironment.

Author: Casimir von Platen
'

function reset() {
    # delete if mongo container exist
    echo "deleting container '$1'"
    docker rm -f $1
    echo "deleting volumes"
    docker volume rm $(docker volume ls -qf dangling=true)
}

function createDockerVolume() {
    local vol=$(docker volume ls -q | grep $1)
    if [[ "$vol" == $1 ]]; then
        echo 'volume available'
    else
        echo "creating volume '$1'"
        local cmd='docker volume create --name '$1
        eval $cmd
    fi
}

function creataDatabaseServer() {
    # starts the mongodb container
    local con=$(docker ps -a | grep $1)
    if [[ "$con" != "" ]]; then
        echo 'container available'
    else
        echo "creating container '$1'"
        docker run \
            --restart=unless-stopped \
            --name $1 \
            --hostname $1 \
            -v $2:/data/db \
            -p 27017:27017 \
            -d mongo --smallfiles \
            --storageEngine wiredTiger
    fi
}

function createDBUserAdmin() {
    local server_user=$(docker exec -i mymongo mongo admin --eval "db.getUser('casimir')" | grep null)
    if [[ "$server_user" == "null" ]]; then
        # server
        echo "creating server_user"
        docker exec -i $1 mongo admin --eval "db.createUser({ user: 'casimir', pwd: 'ok', roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ] })"
    fi
    local db_user=$(docker exec -i mymongo mongo admin --eval "db.getUser('casi')" | grep null)
    if [[ "$db_user" == "null" ]]; then
        # database
        echo "creating db_user"
        docker exec -i $1 mongo admin -u casimir -p ok --eval "db.createUser({ user: 'casi', pwd: 'ok', roles: [ { role: 'dbOwner', db: 'bookstore' } ] })"
    fi
}

function copyDefaultData() {
    docker exec -i $container_name rm -r tmp/
    docker exec -i $container_name mkdir tmp/

    docker cp collections/books.json $1:/tmp
    docker cp collections/authors.json $1:/tmp
    docker cp collections/category.json $1:/tmp
    docker cp collections/publisher.json $1:/tmp
}

function setupDefaultData() {
    local u="casi"
    local p="ok"
    docker exec -i $1 mongo $2 -eval "db.dropDatabase()"
    docker exec -i $1 mongoimport --db $2 --collection books --file /tmp/books.json -u $u -p $p --authenticationDatabase=admin
    docker exec -i $1 mongoimport --db $2 --collection authors --file /tmp/authors.json -u $u -p $p --authenticationDatabase=admin
    docker exec -i $1 mongoimport --db $2 --collection category --file /tmp/category.json -u $u -p $p --authenticationDatabase=admin
    docker exec -i $1 mongoimport --db $2 --collection publisher --file /tmp/publisher.json -u $u -p $p --authenticationDatabase=admin
}

function createServer() {

    # reset
    reset mymongo

    # volume
    local volume_name="mymongodata"
    createDockerVolume $volume_name

    #container
    local container_name="mymongo"
    creataDatabaseServer $container_name $volume_name

    # sleep until server finished creation
    sleep 3

    # db users
    createDBUserAdmin $container_name

    # scripts dir
    docker exec -i $container_name mkdir data/db/scripts
}

function fillAndDump() {
    # copy data
    local container_name="mymongo"
    copyDefaultData $container_name

    # setup data
    local db_name="bookstore"
    setupDefaultData $container_name $db_name

    # dump to tmp/out/ in mongo and then copy to host collections/out/
    docker exec -i $container_name mkdir tmp/out/
    docker exec -i $container_name mongodump --db $db_name --out /tmp/out/
    docker exec -i $container_name bsondump /data/db/storage.bson --outFile /tmp/out/$db_name/storage.json
    docker exec -i $container_name bsondump /tmp/out/$db_name/books.bson --outFile /tmp/out/$db_name/books.json
    docker exec -i $container_name bsondump /tmp/out/$db_name/authors.bson --outFile /tmp/out/$db_name/authors.json
    docker exec -i $container_name bsondump /tmp/out/$db_name/category.bson --outFile /tmp/out/$db_name/category.json
    docker exec -i $container_name bsondump /tmp/out/$db_name/publisher.bson --outFile /tmp/out/$db_name/publisher.json
    docker cp $container_name:/tmp/out/$db_name collections/out/
}

if [[ "$1" == "server" ]]; then
    createServer
fi
if [[ "$1" == "data" ]]; then
    fillAndDump
fi
