#!/bin/bash
 
FILE_DELIM="¬"
START_DIR="/"
 
# TMP FILES
LOG4J2FILES_TMP_FILE="/tmp/log4j2_files.txt"
LOG4J2JARS_TMP_FILE="/tmp/log4j2_jar_files.txt"
LOG4J2CLASSES_TMP_FILE="/tmp/log4j2_classes_files.txt"
LOG4J2CLASSES_ROOTS_TMP_FILE="/tmp/log4j2_classes_roots.txt"
 
# LOG4J2 INFO
LOG4J2_PACKAGE="org/apache/logging/log4j/core/"
LOG4J2_LOGGER_CLASS="${LOG4J2_PACKAGE}Logger.class"
JNDI_MANAGER_CLASS="${LOG4J2_PACKAGE}net/JndiManager.class"
PATCHED_STRING="log4j2"
 
echo "[+] Starting scan for vulnerable log4j2.."
 
# Find log4j2 /war/ear/jar and class files
find $START_DIR -type f -regex ".*\.\([wej]ar\|class\)" -exec bash -c '
list_archive_and_file_if_jar(){
        file="$1"
        if [[ "$file" == *"ar" ]]; then
            for classfile in $(unzip -l $file); do
                    if [[ "$classfile" == *"class" ]]; then
                        echo "${file}¬${classfile}"
                    fi
            done
        elif [[ "$file" == *"class" ]]; then 
            echo "$file"
        fi
}
list_archive_and_file_if_jar "$@"' bash {} \; 2>/dev/null | egrep -i ".*log4j.*core.*/(Logger|JndiManager)\.class" > $LOG4J2FILES_TMP_FILE
 
# Seperate jars and classes
cat $LOG4J2FILES_TMP_FILE | grep "$FILE_DELIM" | awk -F "${FILE_DELIM}" '{print $1}' | sort | uniq > $LOG4J2JARS_TMP_FILE
cat $LOG4J2FILES_TMP_FILE | grep -v "$FILE_DELIM" > $LOG4J2CLASSES_TMP_FILE

# Check jars for vulnerable code
while read jar_file; do
    is_patched=$(unzip -p $jar_file $JNDI_MANAGER_CLASS 2>&1 | grep "$PATCHED_STRING")
    if [[ "${is_patched}" != *"matches" ]]; then
        echo "[!] Vulnerable jar found: ${jar_file}"
    fi
done <$LOG4J2JARS_TMP_FILE

# Find root dirs for unpackaged classes   
while read class_file; do
    echo "$class_file" | awk -F "org" '{print $1}' >> $LOG4J2CLASSES_ROOTS_TMP_FILE
done <$LOG4J2CLASSES_TMP_FILE
cat $LOG4J2CLASSES_ROOTS_TMP_FILE 2>/dev/null | sort | uniq > $LOG4J2CLASSES_ROOTS_TMP_FILE

# Detect vulnerable versions of unpacked classes
while read class_root; do
    jndi_manager="$class_root/$JNDI_MANAGER_CLASS"
    if [ ! -f "$jndi_manager" ]; then
        echo "[!] Vulnerable classes found: ${class_root}${LOG4J2_PACKAGE}"
    else
        is_patched=$(grep "$PATCHED_STRING" "$jndi_manager" 2>&1)
        if [[ "${is_patched}" != *"matches" ]]; then
            echo "[!] Vulnerable classes found: ${class_root}${LOG4J2_PACKAGE}"
        fi
    fi
done <$LOG4J2CLASSES_ROOTS_TMP_FILE 2>/dev/null
 
echo "[+] Finished scan."
 
rm $LOG4J2FILES_TMP_FILE 2>/dev/null
rm $LOG4J2JARS_TMP_FILE 2>/dev/null
rm $LOG4J2CLASSES_TMP_FILE 2>/dev/null
rm $LOG4J2CLASSES_ROOTS_TMP_FILE 2>/dev/null
 
