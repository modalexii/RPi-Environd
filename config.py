#
# This is the configuration file for the RPi environd
#

### Presentation - General

# All datetime stamps use typical strftime codes: https://docs.python.org/2/library/datetime.html#strftime-strptime-behavior

# The date/time stamp of the last (most current) reading.
present_lastread_stamp = "%I:%M %p on %A, %b %d"

# How many decimal places to round to when displaying temperatures. For 
# presentation only - does not impact reading precision in the database.
present_temp_precision = 1


### Presentation - Recent Graph

# The date/time stamp on the x-axis
present_graph_recent_x = "%I:%M %p"

# How many data points to use. 
# This does _not_ reflect how many points will be drawn. Also consider how 
# often the readings are made - e.g., if a value is recorded every 15 minutes,
# then a full day's worth of data requires 24x(60/15) = 96 points.
present_recent_point_count = 720

# How much to reduce the specified number of data points. 
# This is how many points will be drawn. The value of 
# present_recent_point_count is divided in to this many chunks, and then time 
# stamp and value of each chunk is averaged.
present_recent_reduce_to = 16

### Presentation - All Time Graph

# < tbd... not implemented yet > 

### Files

# The static html file that is output. Must be writable by the user running 
# environd. Presumably this is in the www directory of a web server.
www_out = "/var/www/environd.html"

# The template to use for generating static html.
# Must be readable by the user running environd.
html_template = "/opt/environd/template/environd.tpl"

# The (flat text) database file.
# Must be writable by the user running environd, and must exist, even if empty.
database = "/opt/environd/database/temperature_readings.json"

# The log file. Must be writable by the user running environd.
log_file = "/var/log/environd.log"

# Format of the timestamping used internally. 
# Does not impact presentation unless presented values are omitted.
datetime_func_format = "%Y%m%dT%H%M%S"


### Tinker/Debug

# Set to True to print all log messages to the terminal, or False to suppress 
# most output.
terminal_verbosity = True

# The size in mb after which the db file is rotated. 
# The entire db is loaded in to memory, but each reading is a mere 60-80
# bytes, so 100 megs is about 10 years of recording every 15 minutes.
max_db_file_size = 100 # mb
