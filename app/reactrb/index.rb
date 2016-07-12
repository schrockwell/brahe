require 'opal'
require 'browser/interval'
require 'opal-jquery'
require 'opal-activesupport'
require 'json'
require 'react'
require 'react-dom'
require 'reactrb'
require 'dx/grid'

require_relative 'helpers'
require_relative 'maps'
require_relative 'components/updating_satellite_table'
require_relative 'components/updating_passes_table'
require_relative 'components/utc_clock'

Document.ready? do
  qth = DX::Grid.decode("FN31en")

  React.render(
    React.create_element(
      UpdatingSatelliteTable,
        :poll_interval => 0.5,
        :coords => qth,
        :sat_ids => ['07530', '40074', '24278', '40903', '40906', '40910', '27607', '40654', '40967', '25544']
    ),
    Element['#sat-table']
  )

  React.render(
    React.create_element(
      UpdatingPassesTable,
        :coords => qth,
        :sat_ids => ['07530', '40074', '24278', '40903', '40906', '40910', '27607', '40654', '40967', '25544']
    ),
    Element['#passes-table']
  )

  React.render(React.create_element(UTCClock), Element['#utc-clock'])
end
