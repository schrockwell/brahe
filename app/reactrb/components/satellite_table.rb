class SatelliteTable < React::Component::Base
  param :sats, :type => [Hash], :default => []

  def render
    table :class => 'table table-hover' do
      thead do
        tr do
          th { 'Name' }
          th { 'Az' }
          th { 'El' }
          th { 'Alt (km)' }
        end
      end
      tbody do
        if params.sats.count == 0
          tr { td(:colspan => 6) { 'Loading...' } }
        end

        params.sats.each do |sat|
          look = sat['look']

          if look && look['el'] > 5
            tr_class = 'success'
          elsif look && look['el'] > 0
            tr_class = 'warning'
          else
            tr_class = nil
          end

          tr :key => sat['id'], :class => tr_class do
            td { sat['name'] }
            td { look['az'].to_s if look != nil }
            td { look['el'].to_s if look != nil }
            td { sat['alt_km'].to_s }
          end
        end
      end
    end
  end
end