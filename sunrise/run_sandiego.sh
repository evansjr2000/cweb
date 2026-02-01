#!/bin/bash
# Calculate sunrise and sunset times for San Diego, CA on 2026-01-31

# San Diego, CA coordinates
LATITUDE=32.7157
LONGITUDE=-117.1611

# Date: January 31, 2026
YEAR=2026
MONTH=1
DAY=31

./sunrise $LATITUDE $LONGITUDE $YEAR $MONTH $DAY
