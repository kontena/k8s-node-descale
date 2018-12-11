require 'rufus-scheduler'

module K8sNodeDescale
  class Scheduler

    attr_reader :period

    def initialize(period = nil)
      @period = period
    end

    def run(&block)
      period.nil? ? single_shot(&block) : periodic(&block)
    end

    def periodic
      Rufus::Scheduler.new.tap do |scheduler|
        scheduler.every period do
          begin
            Log.info "Running scheduled ec2 kubernetes node descale .."
            yield
          rescue => ex
            Log.error "operation failed: %s : %s" % [ex, ex.message]
          end
        end
      end.join
    end

    def single_shot
      Log.debug { "Running using single-shot proc" }
      begin
        yield
      rescue => ex
        Log.error "operation failed: %s : %s" % [ex, ex.message]
        if ENV["DEBUG"].to_s.empty?
          exit 1
        else
          raise ex
        end
      end
    end
  end
end
