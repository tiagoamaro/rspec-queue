require 'singleton'

module RSpecQueue
  class Configuration
    include Singleton

    attr_accessor :after_worker_spawn_block
    attr_accessor :server_socket

    def self.after_worker_spawn(&block)
      self.instance.after_worker_spawn_block = block
    end

    def self.call_after_worker_spawn_hooks(index)
      self.instance.after_worker_spawn_block.call(index) if self.instance.after_worker_spawn_block
    end

    def worker_count
      @worker_count ||= [env_queue_workers || cpu_count - 1, 1].max
    end

    private

    def env_queue_workers
      ENV['RSPEC_QUEUE_WORKERS'].to_i if ENV['RSPEC_QUEUE_WORKERS']
    end

    def cpu_count
      num_cpus = if `uname`.chomp == "Darwin"
        `/usr/sbin/sysctl -n hw.ncpu`.to_i
      else
        `grep processor /proc/cpuinfo | wc -l`.to_i
      end
    end
  end
end
