import os
from pathlib import Path
from zipfile import ZipFile
import re
import zipfile

START_DIR = "/"
LOG4J2_LOGGER_CLASS = "org/apache/logging/log4j/core/Logger.class"
JNDI_MANAGER_CLASS = "org/apache/logging/log4j/core/net/JndiManager.class"
CONTAINS_STRING_PATTERN = re.compile(b"log4j2")

vulnerable_files_found = []


def is_log4j2_jar(jar_file):
    if zipfile.is_zipfile(jar_file):
        with ZipFile(jar_file, 'r') as jar:
            if LOG4J2_LOGGER_CLASS in jar.namelist():
                return True
    return False


def is_file_patched(binary_file_content):
    if len(CONTAINS_STRING_PATTERN.findall(binary_file_content)) > 0:
        return True
    return False


def check_for_patched_class(jar_file):
    is_class_patched = False
    with ZipFile(jar_file, 'r') as jar:
        if JNDI_MANAGER_CLASS in jar.namelist():
            patched_class = jar.open(JNDI_MANAGER_CLASS)
            is_class_patched = is_file_patched(patched_class.read())
    return is_class_patched


for jar_file in Path(START_DIR).rglob('*.jar'):
    if is_log4j2_jar(jar_file):
        if not check_for_patched_class(jar_file):
            vulnerable_files_found.append(str(jar_file))

for class_file in Path(START_DIR).rglob('*.class'):
    if str(class_file).endswith(LOG4J2_LOGGER_CLASS):
        possible_patched_class = str(class_file).replace(
            LOG4J2_LOGGER_CLASS, JNDI_MANAGER_CLASS)
        is_class_patched = False
        if os.path.isfile(possible_patched_class):
            with open(possible_patched_class, 'rb') as patched_class_file:
                is_class_patched = is_file_patched(patched_class_file.read())
        if not is_class_patched:
            vulnerable_files_found.append(possible_patched_class)

if len(vulnerable_files_found) > 0:
    print("[!] Vulnerable log4j2 files found: ")
    [print(vulnerable_file) for vulnerable_file in vulnerable_files_found]
