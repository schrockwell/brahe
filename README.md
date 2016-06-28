# Brahe!

…get me my potatofeng!

## Installation

Using RVM and Ruby 2.3.x:

```
cd brahe
gem install bundler --no-ri --no-rdoc
bundle
rackup
```

The page is live at `http://localhost:9292/`

## API

### `/current`

#### Query Params

* `from=lat,lng,alt_m` – optional; specify observation location to get current look angles (altitude optional, assumed zero unless specified)
* `ids=07530,25544` – optional; only include certain sats
* `paths=1` – optional; include ground track ± 30 minutes

### `/passes`

#### Query Params

* `from=lat,lng,alt_m` – **required**; specify observation location to get current look angles (altitude optional, assumed zero unless specified)
* `ids=07530,25544` – **required**; specify sats to see passes for