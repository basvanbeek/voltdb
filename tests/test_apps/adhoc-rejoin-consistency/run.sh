#!/usr/bin/env bash

APPNAME="AdHocRejoinConsistency"

if false; then
# find voltdb binaries in either installation or distribution directory.
if [ -n "$(which voltdb 2> /dev/null)" ]; then
    VOLTDB_BIN=$(dirname "$(which voltdb)")
else
    VOLTDB_BIN="$(pwd)/../../bin"
fi
# installation layout has all libraries in $VOLTDB_ROOT/lib/voltdb
if [ -d "$VOLTDB_BIN/../lib/voltdb" ]; then
    VOLTDB_BASE=$(dirname "$VOLTDB_BIN")
    VOLTDB_LIB="$VOLTDB_BASE/lib/voltdb"
    VOLTDB_VOLTDB="$VOLTDB_LIB"
# distribution layout has libraries in separate lib and voltdb directories
else
    VOLTDB_LIB="`pwd`/../../lib"
    VOLTDB_VOLTDB="`pwd`/../../voltdb"
fi
fi
echo $VOLTDIST
: ${VOLTDB_HOME:=$VOLTDIST}

VOLTDB_BASE=$VOLTDB_HOME
VOLTDB_LIB=$VOLTDB_HOME/lib
VOLTDB_BIN=$VOLTDB_HOME/bin
VOLTDB_VOLTDB=$VOLTDB_HOME/voltdb

CLASSPATH=$(ls -x "$VOLTDB_VOLTDB"/voltdb-*.jar | tr '[:space:]' ':')$(ls -x "$VOLTDB_LIB"/*.jar | egrep -v 'voltdb[a-z0-9.-]+\.jar' | tr '[:space:]' ':')
VOLTDB="$VOLTDB_BIN/voltdb"
VOLTCOMPILER="$VOLTDB_BIN/voltcompiler"
LOG4J="$VOLTDB_VOLTDB/log4j.xml"
#LICENSE="$VOLTDB_VOLTDB/license.xml"
LICENSE=$VOLTDB_HOME/voltdb/license.xml
HOST=volt3e
SERVERS=volt3e,volt3f

# remove build artifacts
function clean() {
    rm -rf obj debugoutput $APPNAME.jar voltdbroot voltdbroot
}

# compile the source code for procedures and the client
function srccompile() {
    mkdir -p obj
    javac -target 1.6 -source 1.6 -classpath $CLASSPATH -d obj \
        src/*.java \
        src/procedures/*.java
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# build an application catalog
function catalog() {
    srccompile
    $VOLTCOMPILER obj project.xml $APPNAME.jar
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
    $VOLTCOMPILER obj project2.xml $APPNAME.jar
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
    echo "pwd: $PWD"
}

# run the voltdb server locally
function server() {
    # if a catalog doesn't exist, build one
    catalog #XXX/PSR
    if [ ! -f $APPNAME.jar ]; then catalog; fi
    # run the server
LOG4J_CONFIG_PATH=$PWD/log4j.xml
export LOG4J_CONFIG_PATH
    $VOLTDB create catalog $APPNAME.jar deployment deployment.xml \
        license $LICENSE host $HOST
}

# run the voltdb server locally
function rejoin() {
    # if a catalog doesn't exist, build one
    if [ ! -f $APPNAME.jar ]; then catalog; fi
    # run the server
LOG4J_CONFIG_PATH=$PWD/log4j.xml
export LOG4J_CONFIG_PATH
REJOINHOST=$HOST
    $VOLTDB deployment deployment.xml \
        license $LICENSE live rejoin host $REJOINHOST
}

function serverlegacy() {
    # if a catalog doesn't exist, build one
    if [ ! -f $APPNAME.jar ]; then catalog; fi
    # run the server
    $VOLTDB create catalog $APPNAME.jar deployment deployment.xml \
        license $LICENSE host $HOST
}

# run the client that drives the example
function client() {
    async-benchmark
}

# Asynchronous benchmark sample
# Use this target for argument help
function async-benchmark-help() {
    srccompile
    java -classpath obj:$CLASSPATH:obj sequence.AsyncBenchmark --help
}

function async-benchmark() {
    #srccompile
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$LOG4J \
        AdHocRejoinConsistency.AsyncBenchmark \
        --displayinterval=5 \
        --duration=${DURATION:-300} \
        --servers=$SERVERS \
        --ratelimit=${RATE:-100000} \
        --autotune=false \
        --latencytarget=1 \
        --testcase=UPDATEAPPLICATIONCATALOG
        #--testcase=LOADSINGLEPARTITIONTABLEPTN   # this case fails
        #--testcase=ALL
        #--testcase=LOADMULTIPARTITIONTABLEREP
        #--testcase=WRMULTIPARTSTOREDPROCREP
        #--testcase=WRMULTIPARTSTOREDPROCPTN
        #--testcase=WRSINGLEPARTSTOREDPROCPTN
        #--testcase=ADHOCMULTIPARTREP
        #--testcase=ADHOCSINGLEPARTREP
        #--testcase=ADHOCMULTIPARTPTN
        #--testcase=ADHOCSINGLEPARTPTN
}

function verify() {
    #srccompile
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$LOG4J \
        AdHocRejoinConsistency.CheckReplicaConsistency \
        --servers=${SERVERS}
}

function simple-benchmark() {
    srccompile
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$LOG4J \
        sequence.SimpleBenchmark localhost
}

# Multi-threaded synchronous benchmark sample
# Use this target for argument help
function sync-benchmark-help() {
    srccompile
    java -classpath obj:$CLASSPATH:obj sequence.SyncBenchmark --help
}

function sync-benchmark() {
    srccompile
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$LOG4J \
        sequence.SyncBenchmark \
        --displayinterval=5 \
        --warmup=5 \
        --duration=120 \
        --servers=localhost:21212 \
        --contestants=6 \
        --maxvotes=2 \
        --threads=40
}

# JDBC benchmark sample
# Use this target for argument help
function jdbc-benchmark-help() {
    srccompile
    java -classpath obj:$CLASSPATH:obj sequence.JDBCBenchmark --help
}

function jdbc-benchmark() {
    srccompile
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$LOG4J \
        sequence.JDBCBenchmark \
        --displayinterval=5 \
        --duration=120 \
        --maxvotes=2 \
        --servers=localhost:21212 \
        --contestants=6 \
        --threads=40
}

function help() {
    echo "Usage: ./run.sh {clean|catalog|server|async-benchmark|aysnc-benchmark-help|...}"
    echo "       {...|sync-benchmark|sync-benchmark-help|jdbc-benchmark|jdbc-benchmark-help}"
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else server; fi
