#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script collects data for all classes under test.
#
# Usage:
# get-classes-under-test-data.sh
#
# Requirements:
# - EVOSUITE_JAR   Path to the evosuite.jar file.
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

#
# Print error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

# ------------------------------------------------------------------------- Envs

# Check whether 'subjects' directory exists
SUBJECTS_DIR="$SCRIPT_DIR/../subjects"
[ -d "$SUBJECTS_DIR" ] || die "Could not find 'subjects' directory!"

# Check whether EVOSUITE_JAR is set
[ "$EVOSUITE_JAR" != "" ] || die "EVOSUITE_JAR is not set!"
[ -s "$EVOSUITE_JAR" ] || die "$EVOSUITE_JAR does not exist or it is empty!"

CLASSES_FILE="$SCRIPT_DIR/classes.csv"
[ -s "$CLASSES_FILE" ] || die "[ERROR] $CLASSES_FILE does not exist or it is empty!"

CLASSES_DATA_FILE="$SCRIPT_DIR/classes-data.csv"
echo "project_name,class_name,num_lines,num_statements,num_branches" > "$CLASSES_DATA_FILE"
[ -s "$CLASSES_DATA_FILE" ] || die "[ERROR] $CLASSES_DATA_FILE does not exist or it is empty!"

# ------------------------------------------------------------------------- Main

tmp_output_file="/tmp/get-classes-under-test-data-$USER-$$.txt"

tail -n +2 "$CLASSES_FILE" | while read -r line; do
  subject_name=$(echo "$line" | cut -f1 -d',')
  class_name=$(echo "$line" | cut -f2 -d',')
  echo "[DEBUG] $subject_name::$class_name"

  >"$tmp_output_file" # Clean up temporary file

  pushd . > /dev/null 2>&1
  cd "$SUBJECTS_DIR/$subject_name"
    native_libs=""
    if [ "$subject_name" == "110_firebird" ]; then
      native_libs="$SUBJECTS_DIR/$subject_name/native"
    elif [ "$subject_name" == "27_gangup" ]; then
      native_libs="$SUBJECTS_DIR/$subject_name/native/linux-amd64"
    fi

    java -Xmx512M -jar "$EVOSUITE_JAR" \
      -class "$class_name" \
      -Dcriterion=LINE:STATEMENT:BRANCH \
      -Dsandbox=false \
      -Dmax_loop_iterations=-1 \
      -libraryPath="$native_libs" \
      -printStats > "$tmp_output_file" 2>&1

    echo "[DEBUG] "; cat "$tmp_output_file"

    num_lines=$(cat "$tmp_output_file" | grep "* Criterion LINE: " | cut -c19-)
    num_statements=$(cat "$tmp_output_file" | grep "* Criterion STATEMENT: " | cut -c24-)
    num_branches=$(cat "$tmp_output_file" | grep "* Criterion BRANCH: " | cut -c21-)
  popd > /dev/null 2>&1

  echo "$subject_name,$class_name,$num_lines,$num_statements,$num_branches" >> "$CLASSES_DATA_FILE"
done

rm -f "$tmp_output_file" # Remove temporary file

echo "DONE!"

# EOF
