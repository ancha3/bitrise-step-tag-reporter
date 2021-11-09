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
FORMATTED_TAG_NAME=$(echo $tag_name | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
LIST_TAGS_FILENAME=tag_${FORMATTED_TAG_NAME}_filelist.txt

for dir in ${tag_dirs//,/ }
do
  CURRENT_TAGGED_FILES_COUNT=$(echo $(grep -roh $tag_name $dir* | wc -l))
  TOTAL_TAGGED_FILES_COUNT=`expr $TOTAL_TAGGED_FILES_COUNT + $CURRENT_TAGGED_FILES_COUNT`
  
  if [ ! $CURRENT_TAGGED_FILES_COUNT == "0" ]; then
    grep -rl $tag_name $dir* > $LIST_TAGS_FILENAME
  fi
done

if [ -f "$LIST_TAGS_FILENAME" ]; then
    cp $LIST_TAGS_FILENAME $BITRISE_DEPLOY_DIR/$LIST_TAGS_FILENAME
fi

echo "---- REPORT ----"

if [ ! -f "quality_report.txt" ]; then
    printf "QUALITY REPORT\n\n\n" > quality_report.txt
fi

printf ">>>>>>>>>>  CURRENT TAGGED FILES REPORT  <<<<<<<<<<\n" >> quality_report.txt
printf "Tag name (from config): $tag_name \n" >> quality_report.txt
printf "Tag directory(s) (from config): $tag_dirs \n" >> quality_report.txt

if [ $tag_count_threshold == "-1" ]
then
    printf "Tag count threshold disabled \n" >> quality_report.txt
else
    printf "Tag count threshold (from config): $tag_count_threshold \n" >> quality_report.txt
fi
printf "Current tag count: $TOTAL_TAGGED_FILES_COUNT \n" >> quality_report.txt
printf "You can see list of tagged files into $LIST_TAGS_FILENAME \n\n" >> quality_report.txt

cp quality_report.txt $BITRISE_DEPLOY_DIR/quality_report.txt || true

envman add --key TOTAL_TAGGED_FILES_COUNT --value $TOTAL_TAGGED_FILES_COUNT

if [ !$tag_count_threshold == "-1" ] && [ $TOTAL_TAGGED_FILES_COUNT -gt $tag_count_threshold ]; then
    echo "ERROR: New files have been tagged"
    exit 1
fi
exit 0