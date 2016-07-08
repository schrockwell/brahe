class UTCClock < React::Component::Base
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
    state.now.utc.to_s
  end
end