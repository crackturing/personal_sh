#!/bin/bash
user=$(whoami)

function create_key(){
    ssh-keygen -C "$user@chinatsp.com"
}

create_key
