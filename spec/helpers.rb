require "rspec"
require "eventmachine"

unless RUBY_VERSION < "1.9" || RUBY_PLATFORM =~ /java/
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

module Helpers
  def timer(delay, &callback)
    periodic_timer = EM::PeriodicTimer.new(delay) do
      callback.call
      periodic_timer.cancel
    end
  end

  def async_wrapper(&callback)
    EM.run do
      timer(10) do
        raise "test timed out"
      end
      callback.call
    end
  end

  def async_done
    EM.stop_event_loop
  end
end
