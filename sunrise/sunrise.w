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

@ We define a structure to hold the calculated sunrise and sunset times.

@<Type definitions@>=
typedef struct {
    int hour;
    int minute;
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

    if (argc != 6) {
        printf("Usage: %s <latitude> <longitude> <year> <month> <day>\n", argv[0]);
        printf("Example: %s 40.7128 -74.0060 2024 6 21\n", argv[0]);
        printf("  Latitude: -90 to 90 (negative for South)\n");
        printf("  Longitude: -180 to 180 (negative for West)\n");
        return 1;
    }

    latitude = atof(argv[1]);
    longitude = atof(argv[2]);
    year = atoi(argv[3]);
    month = atoi(argv[4]);
    day = atoi(argv[5]);

    @<Validate input parameters@>@;

    SunTimes times = calculate_sun_times(latitude, longitude, year, month, day);

    @<Display results@>@;

    return 0;
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

@<Display results@>=
printf("Location: %.4f° %s, %.4f° %s\n",
       fabs(latitude), latitude >= 0 ? "N" : "S",
       fabs(longitude), longitude >= 0 ? "E" : "W");
printf("Date: %04d-%02d-%02d\n\n", year, month, day);

if (times.sunrise.valid) {
    printf("Sunrise: %02d:%02d\n", times.sunrise.hour, times.sunrise.minute);
} else {
    printf("Sunrise: No sunrise (polar night or midnight sun)\n");
}

if (times.sunset.valid) {
    printf("Sunset:  %02d:%02d\n", times.sunset.hour, times.sunset.minute);
} else {
    printf("Sunset:  No sunset (polar night or midnight sun)\n");
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
This involves computing the sun's mean anomaly, equation of center, ecliptic
longitude, right ascension, declination, and hour angle.

The |is_sunrise| parameter determines whether we calculate sunrise (1) or sunset (0).

@<Function implementations@>=
double calculate_time_utc(double jd, double lat, double lng, int is_sunrise) {
    double t = (jd - 2451545.0) / 36525.0;  /* Julian centuries since J2000.0 */

    @<Calculate solar mean longitude@>@;
    @<Calculate solar mean anomaly@>@;
    @<Calculate equation of center@>@;
    @<Calculate true longitude and right ascension@>@;
    @<Calculate solar declination@>@;
    @<Calculate hour angle@>@;
    @<Calculate UTC time@>@;

    return utc_time;
}

@ The mean longitude of the sun, corrected for aberration.

@<Calculate solar mean longitude@>=
double mean_long = fmod(280.46646 + 36000.76983 * t + 0.0003032 * t * t, 360.0);
while (mean_long < 0) mean_long += 360.0;

@ The mean anomaly represents the angle between the sun's position and its
position at perihelion (closest approach to Earth).

@<Calculate solar mean anomaly@>=
double mean_anom = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
mean_anom = DEG_TO_RAD(mean_anom);

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

@ The hour angle is the angular distance of the sun from the local meridian.
If the calculation fails (returns NaN), it indicates polar day or night.

@<Calculate hour angle@>=
double cos_hour_angle = (cos(DEG_TO_RAD(ZENITH)) -
                         sin(DEG_TO_RAD(lat)) * sin(DEG_TO_RAD(declination))) /
                        (cos(DEG_TO_RAD(lat)) * cos(DEG_TO_RAD(declination)));

if (cos_hour_angle > 1.0 || cos_hour_angle < -1.0) {
    return -1.0;  /* No sunrise or sunset */
}

double hour_angle = RAD_TO_DEG(acos(cos_hour_angle));
if (!is_sunrise) hour_angle = 360.0 - hour_angle;

@ Convert the hour angle to UTC time, accounting for the equation of time
(the difference between solar time and clock time).

@<Calculate UTC time@>=
double ha_time = hour_angle / 15.0;  /* Convert degrees to hours */
double mean_time = ha_time + right_asc / 15.0 - (0.06571 * t) - 6.622;
double utc_time = fmod(mean_time - lng / 15.0, 24.0);
while (utc_time < 0) utc_time += 24.0;
while (utc_time >= 24.0) utc_time -= 24.0;

@ Convert UTC time (in decimal hours) to local time structure.
This simplified version assumes UTC; timezone support could be added later.

@<Function implementations@>=
void utc_to_local_time(double utc_time, SunTime *result) {
    if (utc_time < 0) {
        result->valid = 0;
        result->hour = 0;
        result->minute = 0;
        return;
    }

    result->valid = 1;
    result->hour = (int)utc_time;
    result->minute = (int)((utc_time - result->hour) * 60.0);
}

@* Index.
