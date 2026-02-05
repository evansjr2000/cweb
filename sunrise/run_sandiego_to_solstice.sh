#!/bin/bash
# Calculate sunrise and sunset times for San Diego, CA
# from today until the summer solstice (June 21, 2026)

# San Diego, CA coordinates
LATITUDE=32.7157
LONGITUDE=-117.1611

# Timezone: P = Pacific, A = Alaska, U = UTC
TIMEZONE=P

# Start date: today
START_DATE=$(date +%Y-%m-%d)

# End date: Summer Solstice 2026
END_DATE="2026-06-21"

# Convert dates to seconds for comparison
current_date="$START_DATE"

echo "Sunrise/Sunset times for San Diego, CA"
echo "From $START_DATE to $END_DATE (Summer Solstice)"
echo "================================================"
echo ""

while [[ "$current_date" < "$END_DATE" ]] || [[ "$current_date" == "$END_DATE" ]]; do
    # Extract year, month, day from current date
    YEAR=$(date -j -f "%Y-%m-%d" "$current_date" +%Y)
    MONTH=$(date -j -f "%Y-%m-%d" "$current_date" +%-m)
    DAY=$(date -j -f "%Y-%m-%d" "$current_date" +%-d)

    ./sunrise $LATITUDE $LONGITUDE $YEAR $MONTH $DAY $TIMEZONE

    # Increment date by 1 day
    current_date=$(date -j -v+1d -f "%Y-%m-%d" "$current_date" +%Y-%m-%d)
done
