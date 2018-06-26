#! /bin/bash

# check root
if [ $(id -u) != 0 ]; then
    PREFIX="sudo"
fi


checkpre() {
    if [ ! $(command -v lsof 2>&1 ) ]; then
        $PREFIX apt install -y lsof
    fi
    if [ ! $(command -v ssh 2>&1 ) ]; then
        $PREFIX apt install -y ssh
    fi
}

help() {
    printf "SSH Tunneling Management Tool\n\n"
    printf "Usage:\ntunman (create|list|clear|remove|*)\n\n"
    exit 0
}

create_tun() {
    printf "socket.file> "
    read SOCKETFILE
    printf "local.port> "
    read LOCALPORT
    printf "remote.port> "
    read REMOTEPORT
    printf "user.name> "
    read USERNAME
    printf "target.adress> "
    read TARGET_ADDRESS

    ssh -f -N -M -S "$SOCKETFILE" -L "$LOCALPORT":127.0.0.1:"$REMOTEPORT" $USERNAME@"$TARGET_ADDRESS"
}

list_tun() {
    let a=0
    for ID in $(lsof -i -n | grep -E "ssh" | awk '{print $2}' | uniq);
    do
        PROCDAT=$(cat /proc/${ID}/cmdline | tr -d "\0")
        SERVER=$(printf ${PROCDAT} | grep -Eo "([a-zA-Z.]+)@([a-zA-Z.0-9]+)" )
        TPATH=$(echo $PROCDAT | grep -Eo "(/[/a-zA-Z.]+)")
        printf "$a $ID $TPATH $SERVER\n"
        let a=a+1
    done

}

clear_tun() {
    for ID in $(lsof -i -n | grep -E "ssh" | awk '{print $2}' | uniq);
    do
        PROCDAT=$(cat /proc/${ID}/cmdline | tr -d "\0")
        SERVER=$(printf ${PROCDAT} | grep -Eo "([a-zA-Z.]+)@([a-zA-Z.0-9]+)" )
        TPATH=$(echo $PROCDAT | grep -Eo "(/[/a-zA-Z.]+)")

        ssh -S $TPATH -O exit $SERVER
    done
}

remove_tun() {
    for ID in $(lsof -i -n | grep -E "ssh" | awk '{print $2}' | uniq);
    do
        if [ "$ID" == "$1" ]; then 
            PROCDAT=$(cat /proc/${ID}/cmdline | tr -d "\0")
            SERVER=$(printf ${PROCDAT} | grep -Eo "([a-zA-Z.]+)@([a-zA-Z.0-9]+)" )
            TPATH=$(echo $PROCDAT | grep -Eo "(/[/a-zA-Z.]+)")
            ssh -S $TPATH -O exit $SERVER    
        fi
    done
}

install_tunman() {
    PPATH=$(cd $(dirname $0); pwd -P)
    BASENAME=$(basename $0)
    $PREFIX cp "$PPATH/$BASENAME" /usr/bin/tun
    $PREFIX chmod a+x /usr/bin/tun

    printf "installed in /usr/local/bin/tun\n"
}


# check, for existsing commands
checkpre

case "$1" in 
    create)
        create_tun
        ;;
    list)
        list_tun
        ;;
    clear)
        clear_tun
        ;;
    remove)
        remove_tun "$2"
        ;;
    install)
        install_tunman
        ;;
    *)
        help
        ;;
esac
