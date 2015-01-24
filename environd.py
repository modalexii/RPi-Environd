#!/usr/bin/python
# -*- coding: utf-8 -*-

## Common

import sys,os,datetime,json

## Our stuff - Change these values for non-default installs 			  [!!]

# The location of config.py
sys.path.append("/etc/environd/")

# location that this script (and thus strings.py) is in
sys.path.append(
	os.path.dirname(
		os.path.realpath(__file__)
	)
)

import strings,config


class Database:
	'''
	Reads, writes and parses the json database.
	After `load()`, this object will have `.content`, a json object. The whole
	file is placed in memory. An `append()` updates the `.content` in memory,
	which can be written to disk via a `commit()`.

	'''

	def maintain(self):
		'''
		Check the size of the database and rotate it if it is larger than the
		configured maximum. Performed as lart of a `load()`. Important only 
		with (very) large data sets because	all data is loaded in to memory. 

		Currently there is no support for accessing data after it has been 
		rotated. The "recent data" graph will appear curt for some time after 
		a rotation until this is implemented.
		'''

		try:
			db_size = os.path.getsize(config.database)
		except OSError:
			log(
				strings.db_missing.format(
					f = config.database,
					c = "%s/config.py" % environd_config_dir,
				)
			)
			exit()

		log(strings.db_size.format(s = str(db_size)), to_file = False)

		if db_size > config.max_db_file_size * 1000:

			log(
				strings.db_rotation.format(
				s = db_size,
				m = config.max_db_file_size
				)
			)

			db_directory = os.path.dirname(config.database)
			db_name = os.path.basename(config.database)

			os.rename(
				config.database, 
				"{p}/hist_ending_{d}_{n}".format(
					p = db_directory,
					d = get_datetime_stamp(),
					n = db_name
				)
			)

		else:

			log(strings.no_db_maintenance, to_file = False)

	def load(self):
		'''
		Fetch the contents of the database and ready a json object.
		'''

		# Mandatory maintainence - don't crash the system with huge datasets
		self.maintain()

		with open(config.database, 'rb') as f:
			try:
				self.content = json.load(f, encoding = 'utf-8')
			except ValueError:
				# The file has no contents (it was probably only `touch`ed), 
				# so set up an empty list.
				log(strings.db_empty)
				self.content = json.loads("[]")

	def append(self,entry):
		'''
		Add data to the end of the dataset. Assumes highest-level dataset is a 
		list.
		'''

		self.content.append(entry)

		log(
			strings.db_append.format(e = json.dumps(entry)), to_file = False
		)

	def commit(self):
		'''
		Write `.content` over the database file. Refuses to write false-y 
		`.content` because obliterating the database is beyond the scope of
		 this application.
		'''

		if self.content:

			with open(config.database, 'wb') as f:
				json.dump(self.content, f, encoding='utf-8')

		else:

			log(db_empty_commit_warning)
			raise UserWarning(strings.db_empty_commit_warning)


class Presentations():
	'''
	Modify data as needed for post-processing or output. 
	Gloms together `Collections()` and `DateTimeStamps()` for semantics.
	'''

	class Collections:
		'''
		Make sets or reductions from the `Database.content`. Requires said
		`Database.content`.
		'''

		def __init__(self, raw_data):
			self.raw_data = raw_data

		def get_nth_point(self, n):
			'''
			Return the item at index `n`.
			'''
			v = self.raw_data[n]
			v[1] = round(v[1], config.present_temp_precision)

			log(
				strings.present_nth_point_result.format(
					n = n,
					v = v
				)
			)

			return v

		def summarize_recent(self):
			'''
			Generate a list of x vals and a listof y valsfor the "Recent Data"
			graph. A relatively large number of the most recent data points
			are reduced via chunking and averaging per values set in 
			config.py. Both datetimes and secsor readings are averaged.
			'''

			# Discard data that is not "recent" as defined by
			# `config.present_recent_point_count`
			n = config.present_recent_point_count
			recent = self.raw_data[-n:] 

			# `recent` is a list of lists [ [],[],[],[],[],[] ]

			# Break up this data in to chunks of size 
			# `config.present_recent_reduce_to`
			n = config.present_recent_reduce_to

			avg = len(recent) / float(n)
			last = 0.0
			chunks = []

			while last < len(recent):
				chunks.append(recent[int(last):int(last + avg)])
				last += avg

			# `chunks` is a list of lists of lists [ [],[],[]], [[],[],[]], ]

			x = [] # hold mean x values (to be returned)
			y = [] # hold mean y values (to be returned)

			for c in chunks:

				# c is a list of lists [ [],[],[] ]

				c_x = [] # hold all the x values in a given chunk
				c_y = [] # hold all the y values in a given chunk

				for t in c:
					# t is a list (with only two elements) []
					c_x.append(t[0])
					c_y.append(t[1])

				# get the mean of this chunk's x/y values
				mean_c_x = Presentations.DateTimeStamps().average_stamps(c_x)
				mean_c_y = reduce(lambda x, y: x + y, c_y) / len(c_y)
				mean_c_y = round(mean_c_y, config.present_temp_precision)

				# add this chunk's mean x val to the averages for all chunks
				x.append(
					# format the datetime as configured
					Presentations.DateTimeStamps(
						# this process does an inefficient number of 
						# datetime object <-> string conversions :(
						mean_c_x.strftime(config.datetime_func_format)
					).present_graph_recent_x()
				)

				# add this chunk's mean y val to the averages for all chunks
				y.append(mean_c_y)

			self.recent_summary = [x,y]

			log(
				strings.present_summarize_recent_results.format(
					s = self.recent_summary
				)
			)

			return self.recent_summary


	class DateTimeStamps:
		'''
		Manage datetime object <-> string conversions, formatting and 
		(semantically-)similar operations.
		Some methods require that this be initialized with a `stamp` (datetime
		object), others do not.
		'''

		def __init__(self, stamp = None):

			if stamp:
				self.stamp = datetime.datetime.strptime(
					stamp,
					config.datetime_func_format,
				)

		def present_lastread_stamp(self):
			'''
			Convert datetime object `.stamp` in to a string per
			`config.present_lastread_stamp`
			'''
			return self.stamp.strftime(config.present_lastread_stamp)

		def present_graph_recent_x(self):
			'''
			Convert datetime object `.stamp` in to a string per
			`config.present_graph_recent_x`
			'''
			return self.stamp.strftime(config.present_graph_recent_x)

		def average_stamps(self, stamps):
			'''
			Find the "average" of a list of datetime strings formatted per 
			`config.datetime_func_format`.
			'''

			deltas = [] # hold unixtimes (unrelated to timedeltas)

			for s in stamps:

				# convert `s` in to a datetime object
				d = Presentations.DateTimeStamps(str(s))

				# convert `d` in to an int representing seconds since the epoch
				d = int(d.stamp.strftime("%s"))

				deltas.append(d)

			# now that all datetimes are ints representing seconds since the
			# epoch, average them normally
			mean_delta = reduce(lambda x, y: x + y, deltas) / len(deltas)

			# convert the mean seconds since the epoch to a datetime object 
			# (and return it, because using Classes "correctly" is overrated)
			return datetime.datetime.fromtimestamp(mean_delta)


def log(info, to_terminal = True, to_file = True):
	'''
	Send strings to the log file and/or terminal.
	`config.terminal_verbosity` overrides `to_terminal` when deciding if a
	message gets echoed, but nothing overrides `to_file`.
	'''

	if to_file:
		with open(config.log_file, "a") as f:
			f.write("%s\n" % info)

	if to_terminal or config.terminal_verbosity:
		print info

def get_temperature():
	'''
	Read the DS18B20 sensor and returns a list with a datetime stamp and a 
	Farenheight reading. Tuples are not used because json is not hip to all
	python data structures.

	Requires https://github.com/timofurrer/w1thermsensor and the kernel mods
	for the DS18B20. Both are included by default in Raspbian & Occidentals,
	though the kernel mods need to be loaded before use.

	This section is more or less copy/pasted from https://learn.adafruit.com/adafruits-raspberry-pi-lesson-11-ds18b20-temperature-sensing/overview
	'''

	from w1thermsensor import W1ThermSensor

	now = datetime.datetime.now()
	datetime_stamp = now.strftime(config.datetime_func_format)

	sensor = W1ThermSensor()
	temperature = sensor.get_temperature(W1ThermSensor.DEGREES_F)

	log(strings.sensor_read.format(t = temperature), to_file = False)

	return [datetime_stamp, temperature]

def regenerate_html(data_collections):
	'''
	Use `Presentations.Collections()` to populate the template located at
	`config.html_template` and dump an html file over `config.www_out`.
	'''

	with open(config.html_template, 'rb') as f:
		template = f.read()

	# fetch the `last_point` - presumably the prominent "current" temperature
	last_point = data_collections.get_nth_point(-1)
	last_point_temp = last_point[1]
	last_point_datetime = (
		Presentations.DateTimeStamps(last_point[0]).present_lastread_stamp()
	)

	# fetch data for the x and y axis of the "Recent Data" graph
	recent_summary = data_collections.summarize_recent()

	graph_recent_xvals = recent_summary[0]
	graph_recent_yvals = recent_summary[1]

	# fill out the template
	html = template.format(**locals())

	log(strings.www_out_write, to_file = False)

	with open(config.www_out, 'wb') as f:
		f.write(html)


def main():

	now = datetime.datetime.now()

	log(
		strings.exec_begin.format(
			t = now.strftime(config.datetime_func_format)
		)
	)

	db = Database()
	db.load()
	db.append(
			get_temperature(),
	)
	db.commit()

	regenerate_html( 
		Presentations().Collections( db.content ) 
	)

	log(strings.exec_end)


main()



