#!/bin/sh

basedir=$PWD


$basedir/transform.ha2marc.sh $basedir CHARCH01
$basedir/remove.marc.namespaces.sh $basedir
$basedir/transform.into.1.line.sh $basedir

