#!/bin/bash

# Check if the directory argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <binhos_path>"
    exit 1
fi

# Initial settings
DIR="$1"
FILE="$DIR/Packages"
TEMP_FILE=$(mktemp)
size_limit=104857600 # 100 MB
packages_count=0
in_metadata=true
current_entry=""

# Check if the file exists
if [[ ! -f "$FILE" ]]; then
    echo "$FILE not found."
    exit 1
fi

process_entry() {
    if [[ -n "$current_entry" ]]; then
        size=$(echo "$current_entry" | grep -Po 'SIZE: \K[0-9]+')
        if (( size <= size_limit )); then
            echo -e "$current_entry" >> "$TEMP_FILE"
        else
            path=$(echo "$current_entry" | grep -Po 'PATH: \K.*')
            if [[ -n "$path" && -f "$DIR/$path" ]]; then
                rm -f "$DIR/$path"
                echo "Removed file: $DIR/$path"
            fi
            ((packages_count--))
        fi
        current_entry=""
    fi
}

# Process the file line by line
while IFS= read -r line || [[ -n $line ]]; do
    if $in_metadata; then
        # In the metadata section
        if [[ "$line" == "PACKAGES:"* ]]; then
            packages_count=$(echo "$line" | awk -F': ' '{print $2}')
        fi

        echo "$line" >> "$TEMP_FILE"

        if [[ -z "$line" ]]; then
            in_metadata=false
        fi
    else
        # In the packages section
        if [[ -n "$line" ]]; then
            current_entry+="$line"$'\n'
        else
            process_entry
        fi
    fi
done < "$FILE"

# Add the last entry if it exists
process_entry

# Update the package count in the temporary file
sed -i "s/^PACKAGES: .*/PACKAGES: $packages_count/" "$TEMP_FILE"
mv "$TEMP_FILE" "$FILE"

