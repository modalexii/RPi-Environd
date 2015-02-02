# RPi Environd

A small utility to record temperature readings from a DS18B20 sensor and present them in static HTML files.

![environd example screen shot](https://cloud.githubusercontent.com/assets/3971017/5994579/e43e1cb6-aa47-11e4-8ae5-d2ec370461f5.png)

## Installation

To install in a Debian-like environment (e.g., Raspbian):

 * Download & extract files
 * Make `install.sh` executable
 * Run `install.sh` as a regular user. You will be asked to elevate privs as necessary via `sudo`.


Something like:

```bash
$ wget https://github.com/modalexii/RPi-Environd/archive/master.zip
$ unzip master.zip
$ cd RPi-Environd-master/
$ chmod +x install.sh
$ ./install.sh
```

The install script does a few things:

* Checks that you are root (not recommended) or can get root via sudo (recommended)
* Checks that the `python` command executed Python version 2.7
* Checks that you have the [w1thermsensor Python library](https://github.com/timofurrer/w1thermsensor). Offers to install it via PIP if not.
* Copies files to their default locations (see **Files & Customization**)
* Installs a cron job to collect a reading and update the HTML at a configurable interval

After install, take a look at `/etc/environd/config.py`. There are many tweakables.

### You also need a web server!

Environd spits out a static HTML file that isn't very interesting to look at without a web server. Something small and simple like lighttpd, nginx or Monkey is recommended. You can Google your way through setting up any of these if you're unsure. 

**Pay special attention to your webserver's document root!** If it is anywhere other than `/var/www/`, you will need to edit either the server config or the Environd config. See **Files & Customization**.

It is also advisable to password-protect the document root with `.htaccess` files or similar, install an SSL certificate and enforce HTTPS-only, _especially_ if you plan to make the server accessible from the Internet. Consult the documentation for your web server.


### You also need a DS18B20 sensor!

Before Environd can do much of anything, you need to buy a sensor and hook it up. There are a few kinds of these available from Adafruit...

* [Tiny transistor form factor](https://www.adafruit.com/product/374)
* [Waterproof](https://www.adafruit.com/product/381)
* [High Temperature & Waterproof](https://www.adafruit.com/product/642)

All 3 kinds get wired up the same. [This tutorial](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-11-ds18b20-temperature-sensing/hardware) breaks it down Barney-style. Note that you would use the same pins on any version of the Raspberry Pi - the first 26 pins of the newer 40-pin models (B+, A+) are the same as the old 26-pin modles.

## Files & Customization


**The application** itself, `environd.py`, must be in the same directory as`strings.py`. The install script puts these in `/opt/environd/`.

**The configuration file** `config.py` must live in `/etc/environd/` _or_ the same directory as `environd.py`. It must be readable by the user that runs Environd.

**The database** name and location can be set in `config.py`. The install script puts it at `/opt/environd/database/temperature_readings.json`. It must be writeable by the user that runs Environd.

**The HTML template** name and location can be set in `config.py`. The install script puts it at `/opt/environd/template/environd.tpl`. It must be readable by the user that runs Environd.

**The web-ready HTML output** name and location can be set in `config.py`. The install script `touch`es this file, but it does not have any content until the application is actually run for the first time. It must be writeable by the user that runs Environd.

[Chart.js](http://www.chartjs.org/) is used to make the pretty graph. The file `Chart.min.js` needs to be in the same directory as the HTML output. The install script copies `Chart.min.js` to the default `/var/www/`. **If you change the `www_out` config line, you MUST also move `Chart.js.min` or else the graph will not render.**

### Customizing the HTML output

You can edit the html template to your heart's desire, with the following constraints:

* The following place holders must exist:
 * "{last_point_temp}" is where the most recent reading is filled in
 * "{last_point_datetime}" is where the datetime stamp associated with the most recent reading is filled in
 * "{graph_recent_xvals}" is where the valus for the graph's x-asis are filled in
 * "{graph_recent_yvals}" is where the valus for the graph's y-asis are filled in
* All other curly braces must be doubbled, e.g., css reading, `p { color: #ccc }` must be changed to read, `p {{ color: #ccc }}`. It is probably easier to include javascipt and css form separate files.

To change the format of the temperature readings or datatime stamps, edit the relevant lines of `config.py`. The strings in the config follow [Python strftime behavior](https://docs.python.org/2/library/datetime.html#strftime-strptime-behavior).

## Todo

The current graph is geared towards displaying "recent" data. I intend to add a 2nd gaph to display all data, or at least a much longer history. 

