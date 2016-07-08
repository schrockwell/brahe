class PassesTable < React::Component::Base
  include BraheHelpers

  param :passes, :type => [Hash], :default => []

  define_state :now => Time.now

  before_mount do
    @updater = every(1) do
      state.now! Time.now
    end
  end

  after_mount do
    @updater.start
    @updater.call
  end

  before_unmount do
    @updater.stop
  end

  def render
    table(:class => 'table table-hover') do
      thead do
        tr do
          th { 'Sat' }
          th(:class => 'interval') { 'Duration' }
          th(:class => 'num') { 'Max El' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'AOS' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'Max' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'LOS' }
        end
        
      end

      tbody do
        if params.passes.count == 0
          tr { td(:col_span => 8) { 'Loading...' } }
        end

        params.passes.each do |pass|
          if pass['aos']['time'] <= state.now.to_i && pass['los']['time'] >= state.now.to_i 
            tr_class = 'success'
          elsif pass['los']['time'] < state.now.to_i  
            tr_class = 'text-muted'
          else
            tr_class = nil
          end

          tr(:class => tr_class) do
            td { pass['sat_name'] }
            td(:class => 'interval') { interval_format(pass['los']['time'] - pass['aos']['time']) }
            td(:class => 'num') { "#{pass['max']['el'].to_s}°" }

            td(:class => 'interval border-left') { interval_format(pass['aos']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['aos']['time']) }
            td(:class => 'az border-right') { az_format(pass['aos']['az']) }

            td(:class => 'interval border-left') { interval_format(pass['max']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['max']['time']) }
            td(:class => 'az border-right') { az_format(pass['max']['az']) }

            td(:class => 'interval border-left') { interval_format(pass['los']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['los']['time']) }
            td(:class => 'az border-right') { az_format(pass['los']['az']) }
          end
        end
      end
    end
  end
end