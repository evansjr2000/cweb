# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **literate programming** project written in CWEB (C + TeX). The single source of truth is `sunrise.w`, which is simultaneously documentation and code. All `.c` and `.tex` files are generated artifacts — edit only `sunrise.w`.

The program calculates sunrise, sunset, and total sunshine duration using the NOAA Solar Calculator algorithm for any latitude/longitude/date, with support for Pacific, Alaska, and UTC timezones including automatic DST adjustment.

## Build System

CWEB tools (`ctangle`, `cweave`, `pdftex`) run inside Docker. The Docker image is `evansjr/cweb:latest`.

```bash
# Ensure Docker is running first
./check_docker.sh

# Full build: extract C, compile executable, generate PDF docs
make all

# Individual targets
make code   # Run ctangle to extract sunrise.c from sunrise.w
make exe    # Compile sunrise.c → sunrise executable (uses local cc)
make doc    # Run cweave + pdftex twice to produce sunrise.pdf

# Clean generated files (keeps PDF)
make clean

# Clean everything including PDF
make cleanall
```

The PDF requires two `pdftex` passes because of the cross-reference system (`\pageref` for glossary links).

## Running the Program

```bash
./sunrise <latitude> <longitude> <year> <month> <day> [timezone]
```

- Timezone: `P` = Pacific (default), `A` = Alaska, `U` = UTC
- DST is determined automatically from the date

```bash
# San Diego, CA example
./sunrise 32.7157 -117.1611 2026 1 31 P

# Anchorage, AK example
./sunrise 61.2181 -149.9003 2026 2 3 A
```

Helper scripts: `run_sandiego.sh` (fixed dates), `run_sandiego_to_solstice.sh` (date range loop).

## CWEB Workflow

CWEB interleaves documentation (plain TeX prose) and C code in named sections called "chunks" using `@<chunk name@>` syntax.

- `@*` — starts a starred section (major heading)
- `@` — starts a minor section
- `@<chunk name@>=` — defines a chunk
- `@<chunk name@>@;` — references/expands a chunk
- `@c` — top-level C code section
- `@^term@>` — adds term to the index

**Key workflow rule:** After modifying `sunrise.w`, always regenerate `sunrise.c` with `make code` before compiling with `make exe`.

## Architecture

All logic lives in `sunrise.w` in this order (as assembled by ctangle):

1. **Header files** — standard C includes
2. **Type definitions** — `SunTime`, `SunTimes` structs
3. **Function prototypes**
4. **Global constants** — `PI`, `ZENITH` (90.833°), timezone offsets/flags
5. **Main program** — argument parsing, timezone selection, DST check, output
6. **Function implementations** (in order):
   - `calculate_julian_day` — converts calendar date to Julian Day Number
   - `day_of_year` — handles leap years
   - `calculate_sun_times` — orchestrates sunrise/sunset calculation
   - `calculate_time_utc` — core NOAA algorithm (broken into sub-chunks)
   - `get_timezone_offset` — returns UTC offset based on `selected_timezone` + `is_dst` globals
   - `utc_to_local_time` — applies offset, handles midnight crossing
   - `calculate_total_sunshine` — difference between sunset and sunrise in hours
   - `get_day_of_week` — Zeller's congruence
   - `is_daylight_saving_time` — US DST rules (second Sun of March → first Sun of November)

The `calculate_time_utc` function uses sequential named chunks for each step of the NOAA algorithm: solar mean longitude → mean anomaly → eccentricity → equation of center → true longitude/right ascension → solar declination → equation of time → hour angle → final UTC time.

Global mutable state: `selected_timezone` (char) and `is_dst` (int) are set in `main` and read by `get_timezone_offset`.

## Docker Helper

`cweb.sh` provides a command-line interface to the Docker container:
```bash
./cweb.sh ctangle sunrise.w   # Extract C code
./cweb.sh cweave sunrise.w    # Generate TeX
./cweb.sh shell               # Interactive shell in container
./cweb.sh build               # Rebuild Docker image
```
