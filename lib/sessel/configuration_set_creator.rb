require 'uri'

module Sessel

  # Takes care of creating the configuration set and making sure all the prerequisites are in place
  class ConfigurationSetCreator

    def initialize(configuration_set)
      @configuration_set = configuration_set
      @ses = Aws::SES::Client.new(region: configuration_set.region)
    end

    def configuration_set
      return @configuration_set
    end

    # Creates the configuration set in SES accoring to the paramteres passed when the object was initialised
    def create()

      rule = {
          configuration_set: {
              name: @configuration_set.configuration_set_name,
          }
      }
      begin
        @ses.create_configuration_set(rule)
      rescue Aws::SES::Errors::ConfigurationSetAlreadyExists
        puts "#{@configuration_set.configuration_set_name} already exists. Skipping."
      end

    end

  end

end