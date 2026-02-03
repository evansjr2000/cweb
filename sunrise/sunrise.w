@* Introduction.
This program calculates sunrise and sunset times for any given location
and date using the simplified NOAA (National Oceanic and Atmospheric
Administration) algorithm. The program demonstrates literate programming
principles by interleaving documentation with code, making the astronomical
calculations transparent and maintainable.

The algorithm accounts for:
\item{$\bullet$} Solar declination (the sun's position relative to Earth's equator)
\item{$\bullet$} Hour angle (the sun's angular distance from the meridian)
\item{$\bullet$} Atmospheric refraction (light bending near the horizon)

@c
@<Header files@>@;
@<Type definitions@>@;
@<Function prototypes@>@;
@<Global constants@>@;
@<Main program@>@;
@<Function implementations@>@;

@ The program requires standard C libraries for mathematical operations,
input/output, and time handling.

@<Header files@>=
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

@ We define constants for the astronomical calculations. The zenith angle
of 90.833 degrees accounts for atmospheric refraction (34 arcminutes) and
the sun's semi-diameter (16 arcminutes).

@<Global constants@>=
#define PI 3.14159265358979323846
#define ZENITH 90.833
#define DEG_TO_RAD(deg) ((deg) * PI / 180.0)
#define RAD_TO_DEG(rad) ((rad) * 180.0 / PI)

/* Timezone offsets from UTC */
#define PST_OFFSET (-8.0)   /* Pacific Standard Time: UTC-8 */
#define PDT_OFFSET (-7.0)   /* Pacific Daylight Time: UTC-7 */
#define AKST_OFFSET (-9.0)  /* Alaska Standard Time: UTC-9 */
#define AKDT_OFFSET (-8.0)  /* Alaska Daylight Time: UTC-8 */

/* Timezone selection */
#define TZ_PACIFIC 'P'
#define TZ_ALASKA 'A'

/* Global timezone setting */
char selected_timezone = TZ_PACIFIC;
int is_dst = 0;

@ We define a structure to hold the calculated sunrise and sunset times.

@<Type definitions@>=
typedef struct {
    int hour;
    double minute;
    int valid;
} SunTime;

typedef struct {
    SunTime sunrise;
    SunTime sunset;
} SunTimes;

@* Main Program.
The main program parses command-line arguments for latitude, longitude,
and date, then calculates and displays the sunrise and sunset times.

Expected usage: |./sunrise <latitude> <longitude> <year> <month> <day>|

@<Main program@>=
int main(int argc, char *argv[]) {
    double latitude, longitude;
    int year, month, day;

    if (argc != 7) {
        printf("Usage: %s <latitude> <longitude> <year> <month> <day> <timezone>\n", argv[0]);
        printf("Example: %s 32.7157 -117.1611 2026 1 31 P\n", argv[0]);
        printf("  Latitude: -90 to 90 (negative for South)\n");
        printf("  Longitude: -180 to 180 (negative for West)\n");
        printf("  Timezone: P = Pacific, A = Alaska\n");
        return 1;
    }

    latitude = atof(argv[1]);
    longitude = atof(argv[2]);
    year = atoi(argv[3]);
    month = atoi(argv[4]);
    day = atoi(argv[5]);

    @<Parse timezone argument@>@;
    @<Validate input parameters@>@;

    /* Determine if DST is in effect for the given date */
    is_dst = is_daylight_saving_time(year, month, day);

    SunTimes times = calculate_sun_times(latitude, longitude, year, month, day);

    @<Display results@>@;

    return 0;
}

@ Parse the timezone argument. Valid values are `P' for Pacific and `A' for Alaska.

@<Parse timezone argument@>=
selected_timezone = argv[6][0];
if (selected_timezone == 'p') selected_timezone = 'P';
if (selected_timezone == 'a') selected_timezone = 'A';
if (selected_timezone != TZ_PACIFIC && selected_timezone != TZ_ALASKA) {
    fprintf(stderr, "Error: Timezone must be P (Pacific) or A (Alaska)\n");
    return 1;
}

@ Input validation ensures the coordinates and date are within valid ranges.

@<Validate input parameters@>=
if (latitude < -90.0 || latitude > 90.0) {
    fprintf(stderr, "Error: Latitude must be between -90 and 90\n");
    return 1;
}
if (longitude < -180.0 || longitude > 180.0) {
    fprintf(stderr, "Error: Longitude must be between -180 and 180\n");
    return 1;
}
if (month < 1 || month > 12) {
    fprintf(stderr, "Error: Month must be between 1 and 12\n");
    return 1;
}
if (day < 1 || day > 31) {
    fprintf(stderr, "Error: Day must be between 1 and 31\n");
    return 1;
}

@ Display the calculated sunrise and sunset times in human-readable format.
The display shows the selected timezone with automatic DST adjustment.
The timezone abbreviation varies based on the timezone selection and DST status.

@<Display results@>=
{
    const char *tz_name;
    if (selected_timezone == TZ_PACIFIC) {
        tz_name = is_dst ? "PDT" : "PST";
    } else {
        tz_name = is_dst ? "AKDT" : "AKST";
    }

    printf("Location: %.4f° %s, %.4f° %s\n",
           fabs(latitude), latitude >= 0 ? "N" : "S",
           fabs(longitude), longitude >= 0 ? "E" : "W");
    printf("Date: %04d-%02d-%02d\n", year, month, day);
    printf("Times shown in %s%s\n\n",
           selected_timezone == TZ_PACIFIC ? "Pacific " : "Alaska ",
           is_dst ? "Daylight Time" : "Standard Time");

    if (times.sunrise.valid) {
        printf("Sunrise: %02d:%07.4f %s\n", times.sunrise.hour, times.sunrise.minute, tz_name);
    } else {
        printf("Sunrise: No sunrise (polar night or midnight sun)\n");
    }

    if (times.sunset.valid) {
        printf("Sunset:  %02d:%07.4f %s\n", times.sunset.hour, times.sunset.minute, tz_name);
    } else {
        printf("Sunset:  No sunset (polar night or midnight sun)\n");
    }

    double sunshine = calculate_total_sunshine(times.sunrise, times.sunset);
    if (sunshine >= 0) {
        int sunshine_hours = (int)sunshine;
        double sunshine_minutes = (sunshine - sunshine_hours) * 60.0;
        printf("\nTotal sunshine: %d hours and %.4f minutes\n", sunshine_hours, sunshine_minutes);
    } else {
        printf("\nTotal sunshine: Cannot calculate (invalid sunrise or sunset)\n");
    }
}

@* Astronomical Calculations.
The core algorithm follows the NOAA method, which calculates the Julian day,
solar position, and time correction factors.

@<Function prototypes@>=
SunTimes calculate_sun_times(double lat, double lng, int year, int month, int day);
int day_of_year(int year, int month, int day);
double calculate_julian_day(int year, int month, int day);
double calculate_time_utc(double julian_day, double lat, double lng, int is_sunrise);
void utc_to_local_time(double utc_time, SunTime *result);
double calculate_total_sunshine(SunTime sunrise, SunTime sunset);
int is_daylight_saving_time(int year, int month, int day);
int get_day_of_week(int year, int month, int day);
double get_timezone_offset(void);

@ The Julian day is a continuous count of days since the beginning of
the Julian Period. It's used as a standard reference for astronomical
calculations.

@<Function implementations@>=
double calculate_julian_day(int year, int month, int day) {
    int a = (14 - month) / 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;

    int jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    return (double)jdn + 0.5;
}

@ Calculate the day of year (1-366) for leap year handling.

@<Function implementations@>=
int day_of_year(int year, int month, int day) {
    int days_per_month[] = {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    int is_leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

    if (is_leap) days_per_month[2] = 29;

    int doy = day;
    for (int i = 1; i < month; i++) {
        doy += days_per_month[i];
    }
    return doy;
}

@ The main calculation function coordinates all the astronomical computations.
It calculates both sunrise and sunset by calling the UTC time calculation
with appropriate flags.

@<Function implementations@>=
SunTimes calculate_sun_times(double lat, double lng, int year, int month, int day) {
    SunTimes times;
    double jd = calculate_julian_day(year, month, day);

    double sunrise_utc = calculate_time_utc(jd, lat, lng, 1);
    double sunset_utc = calculate_time_utc(jd, lat, lng, 0);

    utc_to_local_time(sunrise_utc, &times.sunrise);
    utc_to_local_time(sunset_utc, &times.sunset);

    return times;
}

@ The heart of the algorithm: calculating the exact UTC time of sunrise or sunset.
This implements the NOAA Solar Calculator spreadsheet algorithm, which provides
accurate results by properly computing the equation of time and solar noon.

The |is_sunrise| parameter determines whether we calculate sunrise (1) or sunset (0).

@<Function implementations@>=
double calculate_time_utc(double jd, double lat, double lng, int is_sunrise) {
    double t = (jd - 2451545.0) / 36525.0;  /* Julian centuries since J2000.0 */

    @<Calculate solar mean longitude@>@;
    @<Calculate solar mean anomaly@>@;
    @<Calculate eccentricity@>@;
    @<Calculate equation of center@>@;
    @<Calculate true longitude and right ascension@>@;
    @<Calculate solar declination@>@;
    @<Calculate equation of time@>@;
    @<Calculate hour angle@>@;
    @<Calculate sunrise sunset time@>@;

    return utc_time;
}

@ The mean longitude of the sun, corrected for aberration.

@<Calculate solar mean longitude@>=
double mean_long = fmod(280.46646 + 36000.76983 * t + 0.0003032 * t * t, 360.0);
while (mean_long < 0) mean_long += 360.0;

@ The mean anomaly represents the angle between the sun's position and its
position at perihelion (closest approach to Earth). We normalize to $0$--$360$
degrees.

@<Calculate solar mean anomaly@>=
double mean_anom_deg = fmod(357.52911 + 35999.05029 * t - 0.0001537 * t * t, 360.0);
while (mean_anom_deg < 0) mean_anom_deg += 360.0;
double mean_anom = DEG_TO_RAD(mean_anom_deg);

@ Earth's orbital eccentricity changes slowly over time. This value is needed
for the equation of time calculation.

@<Calculate eccentricity@>=
double eccent = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;

@ The equation of center corrects for Earth's elliptical orbit.

@<Calculate equation of center@>=
double center = sin(mean_anom) * (1.914602 - 0.004817 * t - 0.000014 * t * t)
              + sin(2 * mean_anom) * (0.019993 - 0.000101 * t)
              + sin(3 * mean_anom) * 0.000289;

@ Combine the mean longitude and equation of center to get the sun's
true ecliptic longitude.

@<Calculate true longitude and right ascension@>=
double true_long = mean_long + center;
double apparent_long = true_long - 0.00569 - 0.00478 * sin(DEG_TO_RAD(125.04 - 1934.136 * t));
double obliq = 23.439 - 0.0000004 * t;
double right_asc = RAD_TO_DEG(atan2(cos(DEG_TO_RAD(obliq)) * sin(DEG_TO_RAD(apparent_long)),
                                     cos(DEG_TO_RAD(apparent_long))));
while (right_asc < 0) right_asc += 360.0;
while (right_asc >= 360.0) right_asc -= 360.0;

@ Solar declination is the angle between the sun's rays and the equatorial plane.

@<Calculate solar declination@>=
double declination = RAD_TO_DEG(asin(sin(DEG_TO_RAD(obliq)) * sin(DEG_TO_RAD(apparent_long))));

@ The equation of time accounts for Earth's elliptical orbit and axial tilt,
representing the difference between apparent solar time and mean solar time.
This is essential for accurate sunrise/sunset calculations. The formula
follows the NOAA Solar Calculator spreadsheet algorithm and includes the
orbital eccentricity factor.

@<Calculate equation of time@>=
double var_y = tan(DEG_TO_RAD(obliq / 2.0));
var_y = var_y * var_y;
double eq_time = 4.0 * RAD_TO_DEG(
    var_y * sin(2.0 * DEG_TO_RAD(mean_long))
    - 2.0 * eccent * sin(mean_anom)
    + 4.0 * eccent * var_y * sin(mean_anom) * cos(2.0 * DEG_TO_RAD(mean_long))
    - 0.5 * var_y * var_y * sin(4.0 * DEG_TO_RAD(mean_long))
    - 1.25 * eccent * eccent * sin(2.0 * mean_anom)
);  /* Result in minutes */

@ The hour angle is the angular distance of the sun from the local meridian.
If the calculation fails (returns NaN), it indicates polar day or night.
The hour angle is always returned as a positive value representing the
angular distance from solar noon.

@<Calculate hour angle@>=
double cos_hour_angle = (cos(DEG_TO_RAD(ZENITH)) -
                         sin(DEG_TO_RAD(lat)) * sin(DEG_TO_RAD(declination))) /
                        (cos(DEG_TO_RAD(lat)) * cos(DEG_TO_RAD(declination)));

if (cos_hour_angle > 1.0 || cos_hour_angle < -1.0) {
    return -1.0;  /* No sunrise or sunset */
}

double hour_angle = RAD_TO_DEG(acos(cos_hour_angle));  /* In degrees */

@ Calculate the UTC time using the NOAA formula. Solar noon is calculated
from the equation of time and longitude. Sunrise occurs before solar noon
(subtract hour angle) and sunset occurs after (add hour angle).

@<Calculate sunrise sunset time@>=
/* Solar noon in minutes from midnight UTC */
double solar_noon = (720.0 - 4.0 * lng - eq_time) / 60.0;  /* Convert to hours */

double utc_time;
if (is_sunrise) {
    utc_time = solar_noon - hour_angle / 15.0;  /* Subtract HA for sunrise */
} else {
    utc_time = solar_noon + hour_angle / 15.0;  /* Add HA for sunset */
}

/* Normalize to 0-24 range */
while (utc_time < 0) utc_time += 24.0;
while (utc_time >= 24.0) utc_time -= 24.0;

@ Get the current timezone offset based on the selected timezone and DST status.

@<Function implementations@>=
double get_timezone_offset(void) {
    if (selected_timezone == TZ_PACIFIC) {
        return is_dst ? PDT_OFFSET : PST_OFFSET;
    } else {
        return is_dst ? AKDT_OFFSET : AKST_OFFSET;
    }
}

@ Convert UTC time (in decimal hours) to local time based on the selected
timezone. The function handles day boundary crossings when the local time
falls before midnight or after.

@<Function implementations@>=
void utc_to_local_time(double utc_time, SunTime *result) {
    if (utc_time < 0) {
        result->valid = 0;
        result->hour = 0;
        result->minute = 0;
        return;
    }

    /* Apply timezone offset based on selection and DST */
    double local_time = utc_time + get_timezone_offset();

    /* Handle day boundary crossing */
    while (local_time < 0) local_time += 24.0;
    while (local_time >= 24.0) local_time -= 24.0;

    result->valid = 1;
    result->hour = (int)local_time;
    result->minute = (local_time - result->hour) * 60.0;
}

@ Calculate the total sunshine duration for the day. This computes the
difference between sunset and sunrise times, returning the result in hours
to four decimal places. Returns $-1.0$ if either sunrise or sunset is invalid.

@<Function implementations@>=
double calculate_total_sunshine(SunTime sunrise, SunTime sunset) {
    if (!sunrise.valid || !sunset.valid) {
        return -1.0;
    }

    /* Convert both times to total minutes since midnight */
    double sunrise_minutes = sunrise.hour * 60.0 + sunrise.minute;
    double sunset_minutes = sunset.hour * 60.0 + sunset.minute;

    /* Calculate difference in minutes and convert to hours */
    double sunshine_hours = (sunset_minutes - sunrise_minutes) / 60.0;

    return sunshine_hours;
}

@* Daylight Saving Time Calculation.
US Daylight Saving Time rules (since 2007):
\item{$\bullet$} DST begins: Second Sunday of March at 2:00 AM local time
\item{$\bullet$} DST ends: First Sunday of November at 2:00 AM local time

@ Calculate the day of the week using Zeller's congruence.
Returns 0 for Sunday, 1 for Monday, etc.

@<Function implementations@>=
int get_day_of_week(int year, int month, int day) {
    /* Adjust for January and February */
    if (month < 3) {
        month += 12;
        year--;
    }

    int k = year % 100;
    int j = year / 100;

    int dow = (day + (13 * (month + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7;

    /* Adjust Zeller's result (Saturday=0) to Sunday=0 */
    dow = (dow + 6) % 7;

    return dow;
}

@ Determine if a given date falls within DST.
This implements the US DST rules that have been in effect since 2007.
DST starts on the second Sunday of March and ends on the first Sunday of November.

@<Function implementations@>=
int is_daylight_saving_time(int year, int month, int day) {
    /* DST only applies to months March through November */
    if (month < 3 || month > 11) {
        return 0;  /* January, February, December: Standard time */
    }
    if (month > 3 && month < 11) {
        return 1;  /* April through October: DST */
    }

    /* For March: DST starts on second Sunday */
    if (month == 3) {
        /* Find the second Sunday of March */
        int first_day = get_day_of_week(year, 3, 1);  /* Day of week for March 1 */
        int first_sunday = (first_day == 0) ? 1 : (8 - first_day);  /* First Sunday */
        int second_sunday = first_sunday + 7;  /* Second Sunday */

        /* DST starts at 2 AM on second Sunday */
        return (day >= second_sunday) ? 1 : 0;
    }

    /* For November: DST ends on first Sunday */
    if (month == 11) {
        /* Find the first Sunday of November */
        int first_day = get_day_of_week(year, 11, 1);  /* Day of week for Nov 1 */
        int first_sunday = (first_day == 0) ? 1 : (8 - first_day);  /* First Sunday */

        /* DST ends at 2 AM on first Sunday */
        return (day < first_sunday) ? 1 : 0;
    }

    return 0;  /* Should not reach here */
}

@* Index.
