#!/bin/bash
set -ex

echo "---- CONFIG ----"
if [ -n "$config_file_path" ]; then
    echo "get config from the config file"
    source $config_file_path
else
    echo "get config from bitrise input"
fi

if [[ ${tag_name} == "" ]]; then
    echo "Error: Config keys are not set preperly"
    echo "Error: tag_name is not set "
    exit 1
fi
if [[ ${tag_dirs} == "" ]]; then
    echo "Error: Config keys are not set preperly"
    echo "Error: tag_dirs is not set "
    exit 1
fi

if [[ ${tag_count_threshold} == "" ]]; then
    echo "Error: Config keys are not set preperly"
    echo "Error: tag_count_threshold is not set "
    exit 1
fi

TOTAL_TAGGED_FILES_COUNT=0

for dir in ${dirs//,/ }
do
  CURRENT_TAGGED_FILES_COUNT=$(echo $(grep -roh $tag_name $tag_dirs* | wc -l))
  TOTAL_TAGGED_FILES_COUNT=`expr $TOTAL_TAGGED_FILES_COUNT + $CURRENT_TAGGED_FILES_COUNT`
  grep -rl $tag_name $tag_dirs* >> list_tagged_files.txt
done

echo "---- REPORT ----"

if [ ! -f "quality_report.txt" ]; then
    printf "QUALITY REPORT\n\n\n" > quality_report.txt
fi

printf ">>>>>>>>>>  CURRENT TAGGED FILES  <<<<<<<<<<\n" >> quality_report.txt
printf "Tag name (from config): $tag_name \n" >> quality_report.txt
printf "Tag directory(s) (from config): $tag_dirs \n" >> quality_report.txt
printf "Tag count threshold (from config): $tag_count_threshold \n" >> quality_report.txt
printf "Current tag count: $TOTAL_TAGGED_FILES_COUNT \n" >> quality_report.txt
printf "You can see list of tagged files into list_tagged_files.txt \n\n" >> quality_report.txt

if [ $TOTAL_TAGGED_FILES_COUNT -gt $tag_count_threshold ]; then
    echo "ERROR: New files have been tagged"
    exit 1
fi
exit 0