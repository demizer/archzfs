#!/bin/bash
set -euo pipefail

# Dependencies: jq, curl, bash, rsync
# Config settings
OUTDIR='./repo'
TMPDIR='./repo-tmp'
# End of config settings

rm -rf "${TMPDIR}"
mkdir -p "${OUTDIR}" "${TMPDIR}"

# TODO: Update to use the upstream repository
RELEASE_INFO="$(curl -fsL https://api.github.com/repos/archzfs/archzfs/releases/tags/experimental)"

readarray -t FILE_INFO < <(echo "${RELEASE_INFO}" | jq '.assets | map(.browser_download_url + "|" + .updated_at) | join("\n")' -r)  

for info in "${FILE_INFO[@]}"; do
    url="${info%|*}"
    tmp_filename="${TMPDIR}/$(basename "${url}")"
    filename="${OUTDIR}/$(basename "${url}")"

    updated_at_str="${info#*|}"
    updated_at="$(date '+%s' --date "${updated_at_str}")"
    
    # Calculate old file modified time
    current_at='0'
    if [ -f "${filename}" ]; then
        current_at="$(date '+%s' -r "${filename}")"
    fi

    # Either download or copy pre-existing file
    if [ "${updated_at}" -ne "${current_at}" ]; then
        echo "Downloading ${filename}"
        curl -L -o "${tmp_filename}" "${url}"
        touch -h -d "${updated_at_str}" "${tmp_filename}"
    else
        echo "Skipping ${filename}"
        cp -p "${filename}" "${tmp_filename}"
    fi
done

rsync --delete -av "${TMPDIR}/" "${OUTDIR}/"
