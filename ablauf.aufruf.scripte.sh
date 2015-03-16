#!/bin/sh

basedir=$PWD


#transform.ha2marc.sh $basedir CHARCH01
remove.marc.namespaces.sh $basedir
transform.into.1.line.sh $basedir

