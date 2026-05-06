#!/bin/sh

set -eu

if [ "${PRODUCT_NAME:-}" != "Greek Radio" ]; then
    exit 0
fi

current_build_number="${CURRENT_PROJECT_VERSION:-}"

case "${current_build_number}" in
    ''|*[!0-9]*)
        echo "Skipping build number increment because CURRENT_PROJECT_VERSION is not numeric."
        exit 0
        ;;
esac

next_build_number=$((current_build_number + 1))
project_file_path="${PROJECT_FILE_PATH:-}"
built_info_plist="${TARGET_BUILD_DIR:-}/${INFOPLIST_PATH:-}"

if [ -d "${project_file_path}" ]; then
    project_file_path="${project_file_path}/project.pbxproj"
fi

if [ -n "${project_file_path}" ] && [ -f "${project_file_path}" ]; then
    CURRENT_BUILD_NUMBER="${current_build_number}" \
    NEXT_BUILD_NUMBER="${next_build_number}" \
    /usr/bin/perl -0pi -e 's/CURRENT_PROJECT_VERSION = \Q$ENV{CURRENT_BUILD_NUMBER}\E;/CURRENT_PROJECT_VERSION = $ENV{NEXT_BUILD_NUMBER};/g' "${project_file_path}"
fi

if [ -f "${built_info_plist}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${next_build_number}" "${built_info_plist}" \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${next_build_number}" "${built_info_plist}"
fi

echo "Incremented build number from ${current_build_number} to ${next_build_number}."
