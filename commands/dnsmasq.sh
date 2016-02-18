#!/usr/bin/env bash

# settings

OS=OSX

DNSMASQ_CONFIG_PATH=/usr/local/etc/dnsmasq.conf

# commands

install_dnsmasq ()
{
    # upgrade to bash 4 to get associate arrays ;)
    `python -c \
      "print dict(\
        OSX='_install_dnsmasq_osx',\
        UBUNTU='_install_dnsmasq_ubuntu'\
      ).get('$OS')"\
    `
}

_install_dnsmasq_osx ()
{
    echo Installing Dnsmasq
    brew install dnsmasq

    echo Installing Dnsmasq Configuration File
    cp /usr/local/opt/dnsmasq/dnsmasq.conf.example /usr/local/etc/dnsmasq.conf

    echo "Configuring DNS Tld.dev"
    echo 'nameserver 127.0.0.1' | sudo tee -a /etc/resolver/dev
}

_install_dnsmasq_ubuntu ()
{
    sudo apt-get install -y dnsmasq
}

restart_dnsmasq ()
{
    `python -c \
      "print dict(\
        OSX='_restart_dnsmasq_osx',\
        UBUNTU='_restart_dnsmasq_ubuntu'\
      ).get('$OS')"\
    `
}

_restart_dnsmasq_osx ()
{
    sudo launchctl stop homebrew.mxcl.dnsmasq
    sudo launchctl start homebrew.mxcl.dnsmasq
}

_restart_dnsmasq_ubuntu ()
{
    sudo service dnsmasq restart # ;)
}

set_running_vm_ip_address_records_env_variable ()
{
    DNSMASQ_RECORDS="\n"
    for VM in `vagrant status | grep running | awk '{print $1;}'`;
    do
        # should append something like `address=/api-01.dev/172.28.128.11` to the set of records
        RECORD="address=/$VM"
        RECORD+=".dev/"
        RECORD+=`vagrant ssh $VM \
            -c "ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'"\
        | awk '{print $1}'`
        DNSMASQ_RECORDS+=$RECORD
        DNSMASQ_RECORDS+="\n"
    done
}

configure_dnsmasq_from_current_vagrant_directory ()
{
    echo "Pulling IP addresses from running VMs..."
    set_running_vm_ip_address_records_env_variable && echo $DNSMASQ_RECORDS > $DNSMASQ_CONFIG_PATH
    echo "Updated $DNSMASQ_CONFIG_PATH"
}
