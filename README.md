# Brahe!

…get me my potatofeng!

This Sinatra app downloads [the latest AMSAT two-line Keplerian Elements](http://www.amsat.org/amsat/ftp/keps/current/nasabare.txt), passing them to the [orbit](https://github.com/jeffmcfadden/orbit) gem for calculation. The results are displayed via [Reactrb](http://reactrb.org/) components.

## Installation

Using RVM:

```
# Install Ruby 2.3.0
rvm install 2.3.0

# Go into the root directory of the repo
cd brahe # rvm should automatically detect and create "brahe" gemset

# Install Bundler
gem install bundler --no-ri --no-rdoc

# Install required gems
bundle

# Start Sinatra
rackup
```

The page is live at `http://localhost:9292/`

## API

### `/current`

* `from=lat,lng,alt_m` – optional; specify observation location to get current look angles (altitude optional, assumed zero if omitted)
* `ids=sat_id_1,sat_id_2,…` – optional; only include certain sats (all sats returned if omitted)
* `paths=1` – optional; include ground tracks for each satellite (± 30 minutes)

### `/passes`

* `from=lat,lng,alt_m` – **required**; observation location (altitude optional, assumed zero unless specified)
* `ids=sat_id_1,sat_id_2,…` – **required**; specify sats