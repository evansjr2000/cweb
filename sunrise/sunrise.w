% Cross-reference support for plain TeX (label/pageref mechanism).
% On first pass, \pageref outputs ??; on second pass it outputs the page number.
\openin15=\jobname.xrf
\ifeof15\relax
\else
  \closein15
  \input\jobname.xrf
\fi
\newwrite\xrfout
\immediate\openout\xrfout=\jobname.xrf
\def\label#1{%
  \immediate\write\xrfout{%
    \string\expandafter\string\gdef
    \string\csname\space lbl:#1\string\endcsname{\the\pageno}%
  }%
}
\def\pageref#1{%
  \ifcsname lbl:#1\endcsname\csname lbl:#1\endcsname\else{??}\fi
}

@* Introduction.
@^NOAA Solar Calculator Algorithm@>
@^Literate Programming@>
This program calculates sunrise and sunset times for any given location
and date using the simplified NOAA (National Oceanic and Atmospheric
Administration) algorithm. The program demonstrates literate programming
principles by interleaving documentation with code, making the astronomical
calculations transparent and maintainable.

The algorithm accounts for:
\item{$\bullet$} Solar declination (the sun's position relative to Earth's equator)
@^Solar Declination@>
\item{$\bullet$} Hour angle (the sun's angular distance from the meridian)
@^Hour Angle@>
\item{$\bullet$} Atmospheric refraction (light bending near the horizon)
@^Atmospheric Refraction@>

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
@^Zenith Angle@>
@^Atmospheric Refraction@>
of 90.833 degrees accounts for atmospheric refraction (34 arcminutes) and
the sun's semi-diameter (16 arcminutes). A second zenith constant of exactly
90.0 degrees treats the sun as a geometric point source with no atmospheric
refraction, yielding the purely geometric sunrise and sunset times.

@<Global constants@>=
#define PI 3.14159265358979323846
#define ZENITH 90.833        /* NOAA standard: refraction + semi-diameter */
#define ZENITH_GEOMETRIC 90.0 /* Point source, no atmospheric refraction */
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
#define TZ_UTC 'U'

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

typedef struct {
    SunTimes standard;   /* NOAA standard: includes atmospheric refraction */
    SunTimes geometric;  /* Point source, no atmospheric refraction */
} SunTimesSet;

@* Main Program.
The main program parses command-line arguments for latitude, longitude,
and date, then calculates and displays the sunrise and sunset times.

Expected usage: |./sunrise <latitude> <longitude> <year> <month> <day>|

@<Main program@>=
int main(int argc, char *argv[]) {
    double latitude, longitude;
    int year, month, day;

    if (argc < 6 || argc > 7) {
        printf("Usage: %s <latitude> <longitude> <year> <month> <day> [timezone]\n", argv[0]);
        printf("Example: %s 32.7157 -117.1611 2026 1 31 P\n", argv[0]);
        printf("  Latitude: -90 to 90 (negative for South)\n");
        printf("  Longitude: -180 to 180 (negative for West)\n");
        printf("  Timezone: P = Pacific (default), A = Alaska, U = UTC\n");
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

    SunTimesSet times = calculate_sun_times(latitude, longitude, year, month, day);

    @<Display results@>@;

    return 0;
}

@ Parse the timezone argument. Valid values are `P' for Pacific and `A' for Alaska.
If no timezone is specified, Pacific time is used by default.

@<Parse timezone argument@>=
if (argc == 7) {
    selected_timezone = argv[6][0];
    if (selected_timezone == 'p') selected_timezone = 'P';
    if (selected_timezone == 'a') selected_timezone = 'A';
    if (selected_timezone == 'u') selected_timezone = 'U';
    if (selected_timezone != TZ_PACIFIC && selected_timezone != TZ_ALASKA && selected_timezone != TZ_UTC) {
        fprintf(stderr, "Error: Timezone must be P (Pacific), A (Alaska), or U (UTC)\n");
        return 1;
    }
} else {
    selected_timezone = TZ_PACIFIC;  /* Default to Pacific time */
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
Two sets of results are shown: the standard NOAA calculation (which accounts for
atmospheric refraction and the sun's angular semi-diameter via a zenith of 90.833$^\circ$),
and the geometric calculation (which treats the sun as a point source with no
atmospheric refraction, using a zenith of exactly 90$^\circ$).

@<Display results@>=
{
    const char *tz_name;
    const char *tz_full_name;
    if (selected_timezone == TZ_PACIFIC) {
        tz_name = is_dst ? "PDT" : "PST";
        tz_full_name = is_dst ? "Pacific Daylight Time" : "Pacific Standard Time";
    } else if (selected_timezone == TZ_ALASKA) {
        tz_name = is_dst ? "AKDT" : "AKST";
        tz_full_name = is_dst ? "Alaska Daylight Time" : "Alaska Standard Time";
    } else {
        tz_name = "UTC";
        tz_full_name = "Coordinated Universal Time";
    }

    printf("Location: %.4f\260 %s, %.4f\260 %s\n",
           fabs(latitude), latitude >= 0 ? "N" : "S",
           fabs(longitude), longitude >= 0 ? "E" : "W");
    printf("Date: %04d-%02d-%02d\n", year, month, day);
    printf("Times shown in %s\n\n", tz_full_name);

    /* --- NOAA Standard (with atmospheric refraction) --- */
    printf("=== NOAA Standard (zenith 90.833\260: refraction + solar disc) ===\n");
    if (times.standard.sunrise.valid) {
        printf("Sunrise: %02d:%07.4f %s\n",
               times.standard.sunrise.hour, times.standard.sunrise.minute, tz_name);
    } else {
        printf("Sunrise: No sunrise (polar night or midnight sun)\n");
    }
    if (times.standard.sunset.valid) {
        printf("Sunset:  %02d:%07.4f %s\n",
               times.standard.sunset.hour, times.standard.sunset.minute, tz_name);
    } else {
        printf("Sunset:  No sunset (polar night or midnight sun)\n");
    }
    {
        double sunshine = calculate_total_sunshine(times.standard.sunrise, times.standard.sunset);
        if (sunshine >= 0) {
            int sunshine_hours = (int)sunshine;
            double sunshine_minutes = (sunshine - sunshine_hours) * 60.0;
            printf("Total sunshine: %d hours and %.4f minutes\n\n",
                   sunshine_hours, sunshine_minutes);
        } else {
            printf("Total sunshine: Cannot calculate (invalid sunrise or sunset)\n\n");
        }
    }

    /* --- Geometric (point source, no atmospheric refraction) --- */
    printf("=== Geometric (zenith 90.000\260: point source, no refraction) ===\n");
    if (times.geometric.sunrise.valid) {
        printf("Sunrise: %02d:%07.4f %s\n",
               times.geometric.sunrise.hour, times.geometric.sunrise.minute, tz_name);
    } else {
        printf("Sunrise: No sunrise (polar night or midnight sun)\n");
    }
    if (times.geometric.sunset.valid) {
        printf("Sunset:  %02d:%07.4f %s\n",
               times.geometric.sunset.hour, times.geometric.sunset.minute, tz_name);
    } else {
        printf("Sunset:  No sunset (polar night or midnight sun)\n");
    }
    {
        double sunshine = calculate_total_sunshine(times.geometric.sunrise, times.geometric.sunset);
        if (sunshine >= 0) {
            int sunshine_hours = (int)sunshine;
            double sunshine_minutes = (sunshine - sunshine_hours) * 60.0;
            printf("Total sunshine: %d hours and %.4f minutes\n",
                   sunshine_hours, sunshine_minutes);
        } else {
            printf("Total sunshine: Cannot calculate (invalid sunrise or sunset)\n");
        }
    }

    /* --- Solar Noon Elevation --- */
    {
        double noon_elev = calculate_solar_noon_elevation(latitude, year, month, day);
        printf("\n=== Solar Noon Elevation ===\n");
        printf("Solar elevation angle above horizon at solar noon: %.4f\260\n", noon_elev);
    }
}

@* Astronomical Calculations.
@^NOAA Solar Calculator Algorithm@>
@^Julian Day@>
The core algorithm follows the NOAA method, which calculates the Julian day,
solar position, and time correction factors.

@<Function prototypes@>=
SunTimesSet calculate_sun_times(double lat, double lng, int year, int month, int day);
int day_of_year(int year, int month, int day);
double calculate_julian_day(int year, int month, int day);
double calculate_time_utc(double julian_day, double lat, double lng, int is_sunrise, double zenith);
void utc_to_local_time(double utc_time, SunTime *result);
double calculate_total_sunshine(SunTime sunrise, SunTime sunset);
int is_daylight_saving_time(int year, int month, int day);
int get_day_of_week(int year, int month, int day);
double get_timezone_offset(void);
double calculate_solar_noon_elevation(double lat, int year, int month, int day);

@ The Julian day @^Julian Day@> is a continuous count of days since the beginning of
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
It calculates both sunrise and sunset for two zenith values: the NOAA standard
(90.833$^\circ$, accounting for atmospheric refraction and solar disc) and the
geometric case (90.0$^\circ$, treating the sun as a point source with no refraction).

@<Function implementations@>=
SunTimesSet calculate_sun_times(double lat, double lng, int year, int month, int day) {
    SunTimesSet result;
    double jd = calculate_julian_day(year, month, day);

    /* Standard NOAA calculation: zenith includes refraction and solar semi-diameter */
    double sunrise_utc = calculate_time_utc(jd, lat, lng, 1, ZENITH);
    double sunset_utc  = calculate_time_utc(jd, lat, lng, 0, ZENITH);
    utc_to_local_time(sunrise_utc, &result.standard.sunrise);
    utc_to_local_time(sunset_utc,  &result.standard.sunset);

    /* Geometric calculation: sun as point source, no atmospheric refraction */
    double sunrise_geo = calculate_time_utc(jd, lat, lng, 1, ZENITH_GEOMETRIC);
    double sunset_geo  = calculate_time_utc(jd, lat, lng, 0, ZENITH_GEOMETRIC);
    utc_to_local_time(sunrise_geo, &result.geometric.sunrise);
    utc_to_local_time(sunset_geo,  &result.geometric.sunset);

    return result;
}

@ The heart of the algorithm: calculating the exact UTC @^UTC@> time of sunrise or sunset.
@^NOAA Solar Calculator Algorithm@>
This implements the NOAA Solar Calculator spreadsheet algorithm, which provides
accurate results by properly computing the equation of time and solar noon.

The |is_sunrise| parameter determines whether we calculate sunrise (1) or sunset (0).

@<Function implementations@>=
double calculate_time_utc(double jd, double lat, double lng, int is_sunrise, double zenith) {
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

@ The solar mean longitude @^Solar Mean Longitude@> of the sun, corrected for
{\it aberration\/} @^Aberration@> (see Glossary, p.~\pageref{gloss:aberration}).

@<Calculate solar mean longitude@>=
double mean_long = fmod(280.46646 + 36000.76983 * t + 0.0003032 * t * t, 360.0);
while (mean_long < 0) mean_long += 360.0;

@ The {\it mean anomaly\/} @^Mean Anomaly@>@^Solar Mean Anomaly@>
(see Glossary, p.~\pageref{gloss:mean_anomaly})
represents the angle between the sun's position and its
position at perihelion (closest approach to Earth). We normalize to $0$--$360$
degrees.

@<Calculate solar mean anomaly@>=
double mean_anom_deg = fmod(357.52911 + 35999.05029 * t - 0.0001537 * t * t, 360.0);
while (mean_anom_deg < 0) mean_anom_deg += 360.0;
double mean_anom = DEG_TO_RAD(mean_anom_deg);

@ Earth's {\it orbital eccentricity\/} @^Orbital Eccentricity@>
(see Glossary, p.~\pageref{gloss:eccentricity})
changes slowly over time. This value is needed
for the equation of time calculation.

@<Calculate eccentricity@>=
double eccent = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;

@ The {\it equation of center\/} @^Equation of Center@>
(see Glossary, p.~\pageref{gloss:eq_of_center})
corrects for Earth's elliptical orbit.

@<Calculate equation of center@>=
double center = sin(mean_anom) * (1.914602 - 0.004817 * t - 0.000014 * t * t)
              + sin(2 * mean_anom) * (0.019993 - 0.000101 * t)
              + sin(3 * mean_anom) * 0.000289;

@ Combine the mean longitude and equation of center to get the sun's
true ecliptic longitude. @^True Longitude@>@^Right Ascension@>

@<Calculate true longitude and right ascension@>=
double true_long = mean_long + center;
double apparent_long = true_long - 0.00569 - 0.00478 * sin(DEG_TO_RAD(125.04 - 1934.136 * t));
double obliq = 23.439 - 0.0000004 * t;
double right_asc = RAD_TO_DEG(atan2(cos(DEG_TO_RAD(obliq)) * sin(DEG_TO_RAD(apparent_long)),
                                     cos(DEG_TO_RAD(apparent_long))));
while (right_asc < 0) right_asc += 360.0;
while (right_asc >= 360.0) right_asc -= 360.0;

@ Solar declination @^Solar Declination@> is the angle between the sun's rays and the equatorial plane.

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

@ The hour angle @^Hour Angle@> is the angular distance of the sun from the local meridian.
@^Zenith Angle@>@^Atmospheric Refraction@>@^Solar Declination@>
If the calculation fails (returns NaN), it indicates polar day or night.
The hour angle is always returned as a positive value representing the
angular distance from solar noon.

@<Calculate hour angle@>=
double cos_hour_angle = (cos(DEG_TO_RAD(zenith)) -
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

@ Get the current timezone @^Timezone@>@^UTC@> offset based on the selected timezone and DST status.

@<Function implementations@>=
double get_timezone_offset(void) {
    if (selected_timezone == TZ_PACIFIC) {
        return is_dst ? PDT_OFFSET : PST_OFFSET;
    } else if (selected_timezone == TZ_ALASKA) {
        return is_dst ? AKDT_OFFSET : AKST_OFFSET;
    } else {
        return 0.0;  /* UTC has no offset */
    }
}

@ Convert UTC @^UTC@> time (in decimal hours) to local time based on the selected
timezone. @^Timezone@> The function handles day boundary crossings when the local time
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

@ Calculate the solar elevation angle above the horizon at solar noon.
@^Solar Noon@>@^Solar Declination@>@^Hour Angle@>
The {\it elevation angle\/} is the angle between the Sun and the observer's
horizon, measured upward from the horizon plane ($0\deg$ at the horizon,
$90\deg$ directly overhead). At {\it solar noon\/}
(see Glossary, p.~\pageref{gloss:solar_noon}) the hour angle
(see Glossary, p.~\pageref{gloss:hour_angle}) is zero, so the general altitude formula
reduces to:
$$\sin(\alpha) = \sin(\phi)\sin(\delta) + \cos(\phi)\cos(\delta)$$
where $\alpha$ is the elevation angle above the horizon, $\phi$ is the observer's
latitude, and $\delta$ is the solar declination
(see Glossary, p.~\pageref{gloss:solar_decl}).
The function recomputes the declination from the Julian day using the same NOAA
intermediate quantities as |calculate_time_utc|.

@<Function implementations@>=
double calculate_solar_noon_elevation(double lat, int year, int month, int day) {
    double jd = calculate_julian_day(year, month, day);
    double t = (jd - 2451545.0) / 36525.0;  /* Julian centuries since J2000.0 */

    /* Solar mean longitude */
    double mean_long = fmod(280.46646 + 36000.76983 * t + 0.0003032 * t * t, 360.0);
    while (mean_long < 0) mean_long += 360.0;

    /* Solar mean anomaly */
    double mean_anom_deg = fmod(357.52911 + 35999.05029 * t - 0.0001537 * t * t, 360.0);
    while (mean_anom_deg < 0) mean_anom_deg += 360.0;
    double mean_anom = DEG_TO_RAD(mean_anom_deg);

    /* Equation of center */
    double center = sin(mean_anom) * (1.914602 - 0.004817 * t - 0.000014 * t * t)
                  + sin(2 * mean_anom) * (0.019993 - 0.000101 * t)
                  + sin(3 * mean_anom) * 0.000289;

    /* Apparent ecliptic longitude */
    double true_long = mean_long + center;
    double apparent_long = true_long - 0.00569
                         - 0.00478 * sin(DEG_TO_RAD(125.04 - 1934.136 * t));
    double obliq = 23.439 - 0.0000004 * t;  /* Obliquity of the ecliptic */

    /* Solar declination */
    double declination = RAD_TO_DEG(
        asin(sin(DEG_TO_RAD(obliq)) * sin(DEG_TO_RAD(apparent_long))));

    /* Elevation at solar noon: hour angle = 0, so cos(HA) = 1 */
    double sin_elev = sin(DEG_TO_RAD(lat)) * sin(DEG_TO_RAD(declination))
                    + cos(DEG_TO_RAD(lat)) * cos(DEG_TO_RAD(declination));
    return RAD_TO_DEG(asin(sin_elev));
}

@* Daylight Saving Time Calculation.
@^Timezone@>
US Daylight Saving Time rules (since 2007):
\item{$\bullet$} DST begins: Second Sunday of March at 2:00 AM local time
\item{$\bullet$} DST ends: First Sunday of November at 2:00 AM local time

@ Calculate the day of the week using Zeller's congruence. @^Zeller's Congruence@>
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

@* Glossary.
The following astronomical and computational terms are used in this program.
Entries are arranged alphabetically.

\medskip
\noindent\label{gloss:aberration}{\bf Aberration.}\quad
The apparent displacement of a celestial body from its true geometric position,
caused by the finite speed of light combined with Earth's orbital motion around
the Sun. Because light takes time to travel from the Sun to Earth, the Sun
appears shifted slightly in the direction of Earth's motion. The annual
aberration reaches a maximum of about 20.5 arcseconds. In this program,
aberration is accounted for in the computation of the Sun's apparent longitude
by subtracting a small correction term ($0.00569$ degrees) from the true
ecliptic longitude.

\medskip
\noindent\label{gloss:atm_refraction}{\bf Atmospheric Refraction.}\quad
The bending of light as it passes through Earth's atmosphere, causing the Sun
to appear slightly higher above the horizon than its true geometric position.
Refraction is strongest near the horizon, where light traverses the greatest
thickness of air. The standard correction near the horizon amounts to
approximately 34~arcminutes. In this program, atmospheric refraction is combined
with the Sun's angular semi-diameter (16~arcminutes) in the zenith angle
(see Glossary, p.~\pageref{gloss:zenith}) of 90.833$\deg$, which defines the
threshold for sunrise and sunset calculations.

\medskip
\noindent\label{gloss:eq_of_center}{\bf Equation of Center.}\quad
The angular difference between the Sun's true anomaly (its actual position in
the elliptical orbit) and its mean anomaly (the position it would occupy in a
uniform circular orbit). It arises from Kepler's second law: a planet moves
faster near perihelion and slower near aphelion. The equation of center is
computed as a Fourier series in the mean anomaly and is added to the mean
longitude to obtain the Sun's true ecliptic longitude. At Earth's eccentricity,
the equation of center reaches a maximum of roughly $1.9$ degrees.

\medskip
\noindent\label{gloss:hour_angle}{\bf Hour Angle.}\quad
The angular distance of the Sun westward from the local meridian, measured
along the celestial equator and expressed in degrees (where $15\deg = 1$~hour).
The hour angle is zero at solar noon (see Glossary, p.~\pageref{gloss:solar_noon}),
negative before noon, and positive after noon. At sunrise and sunset, the hour angle has equal magnitude and opposite
sign. In this program, the hour angle is derived from the solar declination
(see Glossary, p.~\pageref{gloss:solar_decl}) and the observer's latitude,
using the zenith angle (see Glossary, p.~\pageref{gloss:zenith}) to account
for atmospheric refraction (see Glossary, p.~\pageref{gloss:atm_refraction}).

\medskip
\noindent\label{gloss:julian_day}{\bf Julian Day.}\quad
A continuous count of days and fractions of days since noon, January~1,
4713~BC (Julian calendar), used as a universal reference for astronomical
calculations. The integer part is the Julian Day Number; the fractional part
represents the time within the day. Using Julian Days eliminates calendar
irregularities such as leap years and varying month lengths. In this program,
the Julian Day is converted to Julian centuries since the J2000.0 epoch
(noon, January~1, 2000~UTC), which is the time variable used throughout the
NOAA solar algorithm (see Glossary, p.~\pageref{gloss:noaa}).

\medskip
\noindent\label{gloss:literate_prog}{\bf Literate Programming.}\quad
A software development methodology introduced by Donald~E. Knuth in which a
program is written primarily as a human-readable narrative, with code woven
into the prose. The documentation and code are maintained in a single source
file; two tools extract the components: {\tt ctangle} produces compilable
C~code, and {\tt cweave} generates \TeX\ source for typeset documentation.
This program is written in the CWEB variant of literate programming, and the
document you are reading was produced by {\tt cweave} from {\tt sunrise.w}.

\medskip
\noindent\label{gloss:mean_anomaly}{\bf Mean Anomaly (Solar Mean Anomaly).}\quad
The angle that would be swept out by a hypothetical planet moving at uniform
speed in a circular orbit of the same period as the actual elliptical orbit,
measured from the point of perihelion (the point of closest approach to the
Sun). The mean anomaly increases linearly with time and is used as the starting
point for computing the true position of the Sun in its elliptical orbit. The
difference between the true anomaly and the mean anomaly is the equation of
center (see Glossary, p.~\pageref{gloss:eq_of_center}).

\medskip
\noindent\label{gloss:noaa}{\bf NOAA Solar Calculator Spreadsheet Algorithm.}\quad
A method for computing sunrise and sunset times developed by the National
Oceanic and Atmospheric Administration (NOAA) Earth System Research Laboratory,
based on Jean Meeus's {\it Astronomical Algorithms}. The algorithm computes
Julian centuries since J2000.0, the solar mean longitude
(see Glossary, p.~\pageref{gloss:solar_mean_long}), mean anomaly
(see Glossary, p.~\pageref{gloss:mean_anomaly}), equation of center
(see Glossary, p.~\pageref{gloss:eq_of_center}), true and apparent longitude,
solar declination (see Glossary, p.~\pageref{gloss:solar_decl}), equation of
time, and the hour angle (see Glossary, p.~\pageref{gloss:hour_angle}) at
sunrise and sunset. It provides accuracy within approximately one minute
for dates within several centuries of the present.

\medskip
\noindent\label{gloss:eccentricity}{\bf Orbital Eccentricity.}\quad
A dimensionless parameter that describes how much an elliptical orbit deviates
from a perfect circle. An eccentricity of $0$ corresponds to a circular orbit,
while a value approaching $1$ describes a highly elongated ellipse. Earth's
orbital eccentricity is approximately $0.0167$, meaning the Sun--Earth distance
varies by about 3.3\% between perihelion (early January) and aphelion (early
July). This small variation causes the equation of time to depart from zero and
affects the duration of the seasons.

\medskip
\noindent\label{gloss:right_asc}{\bf Right Ascension.}\quad
The celestial equivalent of geographic longitude, measuring the angular distance
of a point on the celestial sphere eastward along the celestial equator from
the vernal equinox, expressed in hours, minutes, and seconds (where
$24^{\rm h} = 360\deg$). In this program, the Sun's right ascension is computed
from its apparent ecliptic longitude and the obliquity of the ecliptic using
the two-argument arctangent function, and serves as an intermediate step in
computing the equation of time.

\medskip
\noindent\label{gloss:solar_decl}{\bf Solar Declination.}\quad
The angle between the Sun's rays and the plane of Earth's equator, ranging
from $+23.5\deg$ at the June solstice to $-23.5\deg$ at the December solstice,
passing through zero at the equinoxes. Solar declination determines how high
the Sun rises and how long it remains above the horizon each day. In this
program, declination is computed from the Sun's apparent ecliptic longitude and
the obliquity of the ecliptic (Earth's axial tilt of approximately $23.4\deg$).

\medskip
\noindent\label{gloss:solar_mean_long}{\bf Solar Mean Longitude.}\quad
The ecliptic longitude the Sun would have if it moved at a perfectly uniform
rate in a circular orbit, without perturbation from Earth's elliptical motion.
It increases by approximately $360\deg$ per year. The difference between the
true longitude (see Glossary, p.~\pageref{gloss:true_long}) and the mean
longitude is primarily the equation of center
(see Glossary, p.~\pageref{gloss:eq_of_center}). A further correction for
aberration (see Glossary, p.~\pageref{gloss:aberration}) yields the apparent
longitude used in the declination and right ascension calculations.

\medskip
\noindent\label{gloss:solar_noon}{\bf Solar Noon.}\quad @^Solar Noon@>
The moment each day when the Sun reaches its highest point in the sky and
crosses the observer's local meridian, exactly halfway between sunrise and
sunset in terms of the Sun's position. At solar noon, the hour angle
(see Glossary, p.~\pageref{gloss:hour_angle}) is zero and the Sun is due
south (in the Northern Hemisphere). Solar noon does not coincide with
12:00~local clock time in general, because clock time is fixed to timezone
boundaries and does not follow the Sun's actual motion; additionally, the
equation of time---the accumulated effect of Earth's elliptical orbit and
axial tilt---shifts solar noon by up to about 16~minutes ahead or behind
mean solar time throughout the year. In this program, solar noon is
implicitly determined through the equation-of-time and Julian Day
calculations used by the NOAA algorithm (see Glossary, p.~\pageref{gloss:noaa}).

\medskip
\noindent\label{gloss:timezone}{\bf Timezone.}\quad
A region of the globe that observes the same standard time, defined as an
offset from Coordinated Universal Time (UTC,
see Glossary, p.~\pageref{gloss:utc}). This program supports three timezone
options: Pacific Time (UTC$-8$ standard, UTC$-7$ daylight saving time),
Alaska Time (UTC$-9$ standard, UTC$-8$ daylight saving time), and UTC itself.
Daylight saving time is determined automatically from the input date using
current US DST rules (second Sunday of March through first Sunday of November).

\medskip
\noindent\label{gloss:true_long}{\bf True Longitude.}\quad
The Sun's actual ecliptic longitude, obtained by adding the equation of center
(see Glossary, p.~\pageref{gloss:eq_of_center}) to the solar mean longitude
(see Glossary, p.~\pageref{gloss:solar_mean_long}). It represents the Sun's
true position in its elliptical orbit projected onto the ecliptic plane. A
further small correction for nutation and aberration
(see Glossary, p.~\pageref{gloss:aberration}) yields the apparent longitude,
from which the solar declination (see Glossary, p.~\pageref{gloss:solar_decl})
and right ascension (see Glossary, p.~\pageref{gloss:right_asc}) are derived.

\medskip
\noindent\label{gloss:utc}{\bf UTC (Coordinated Universal Time).}\quad
The primary international time standard by which the world regulates clocks.
UTC is kept by a weighted average of more than 400 atomic clocks in over
50~national laboratories worldwide, occasionally adjusted by leap seconds to
remain within $0.9$~seconds of UT1 (astronomical time based on Earth's
rotation). All local timezone offsets are defined relative to UTC. In this
program, sunrise and sunset times are first computed in UTC using the NOAA
algorithm (see Glossary, p.~\pageref{gloss:noaa}), then converted to the
selected local timezone (see Glossary, p.~\pageref{gloss:timezone}).

\medskip
\noindent\label{gloss:zeller}{\bf Zeller's Congruence.}\quad
A formula developed by Christian Zeller in 1887 for determining the day of the
week from any given Gregorian calendar date, using modular arithmetic to map
the date to an integer from~0 to~6. In this program, Zeller's congruence is
used to locate the second Sunday of March (beginning of daylight saving time)
and the first Sunday of November (end of daylight saving time), enabling
automatic DST adjustment for Pacific and Alaska timezones
(see Glossary, p.~\pageref{gloss:timezone}).

\medskip
\noindent\label{gloss:zenith}{\bf Zenith Angle.}\quad
The angle between the Sun and the observer's zenith (the point directly
overhead), complementary to the altitude angle. A zenith angle of $0\deg$
means the Sun is overhead; $90\deg$ places it geometrically on the horizon.
For sunrise and sunset, a zenith angle of $90.833\deg$ is used in the NOAA
standard calculation, accounting for two effects: (1)~atmospheric refraction
(see Glossary, p.~\pageref{gloss:atm_refraction}) bends sunlight upward by
approximately 34~arcminutes, making the Sun appear above the horizon even when
geometrically below it; and (2)~the Sun's angular semi-diameter of
16~arcminutes, so that sunrise is defined as the moment the Sun's upper limb
appears at the horizon.
This program also computes a {\it geometric\/} sunrise and sunset using a
zenith angle of exactly $90\deg$, which treats the Sun as a point source with
no atmospheric refraction. The difference between the two results (typically
2--3~minutes at mid-latitudes) quantifies the combined effect of refraction and
the solar disc size.

@* Index.
