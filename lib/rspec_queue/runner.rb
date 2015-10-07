require 'rspec/core'
require 'rspec_queue/configuration'
require 'rspec_queue/server'
require 'rspec_queue/worker'

module RSpecQueue
  class Runner < RSpec::Core::Runner
    def run_specs(example_groups)
      example_group_hash = example_groups.map { |example_group|
        [example_group.id, example_group]
      }.to_h

      # start the server, so we are ready to accept connections from workers
      server = RSpecQueue::Server.new

      RSpecQueue::Configuration.call_before_fork_hooks
      RSpecQueue::Configuration.instance.server_socket = server.socket_path

      RSpecQueue::Worker.each do |worker|
        reporter = @configuration.reporter

        while(worker.has_work?)
          # can we pass in a custom reporter which instantly reports back
          # to the server?
          example_group_hash[worker.current_example].run(reporter)
        end

        # report the results of the examples run to the master process
        worker.finish(reporter)

        # terminate the fork
        Process.exit
      end

      reporter = @configuration.reporter

      reporter.report(0) do |report|
        server.dispatch(example_group_hash, report)
        [report.failed_examples.count, 1].min # exit status
      end
    ensure
      server.close
    end
  end
end
