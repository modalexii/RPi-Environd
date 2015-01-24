#!/usr/bin/python
# -*- coding: utf-8 -*-

exec_begin = "Began new execution at {t}"
exec_end = "Ended.\n"
sensor_read = "Got temperature reading: {t}° F"
db_size = "Database size is {s} bytes"
db_rotation = "DB larger than max size ({s}/{m} mb). Rotating file."
db_empty = "Database file is empty. Creating new list to append to."
no_db_maintenance = "No DB maintenance needed."
db_append = "Appending to database file: {e}"
db_missing = "No database file found at {f}. Either edit the config ({c}) to point to a database file, or `touch {f}` to create one."
db_empty_commit_warning = "Refusing to commit empty database"
www_out_write = "Overwriting www_out file"
present_summarize_recent_results = "Recent Point Summary: {s}"
present_nth_point_result = "Nth point requested,  n = {n}, value = {v}"