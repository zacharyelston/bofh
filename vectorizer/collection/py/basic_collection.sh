#!/bin/bash
# Basic collection using standard Unix tools

find "$1" -type f -exec stat -c "%n|%s|%Y|%A|%F|%u|%g|%h|%X|%Z" {} \; > raw_metadata.txt
