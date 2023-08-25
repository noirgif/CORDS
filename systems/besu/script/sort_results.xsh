#!/bin/xonsh

$log_dir = 'inject-results-single'

directories = ['error', 'wrong', 'normal']

mkdir -p $log_dir/@(directories)
errors = $(ls $log_dir).split()
for directory in directories:
    errors.remove(directory)

pushd .
cd $log_dir

for error in errors:
    if $(cat @(error)/read.log 2> /dev/null) == 'Contract data validated':
        mv @(error) normal
    elif ![ls @(error)/error &> /dev/null]:
        mv @(error) error
    else:
        mv @(error) wrong

popd