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

      event_destinaton = {
          configuration_set_name: @configuration_set.configuration_set_name,
          event_destination: {
              name: "#{@configuration_set.configuration_set_name}EventName",
              enabled: true,
              matching_event_types: ['send', 'reject', 'bounce', 'complaint', 'delivery'],
              cloud_watch_destination: {
                  dimension_configurations: [
                      {
                          dimension_name: 'To',
                          dimension_value_source: 'emailHeader',
                          default_dimension_value: 'DestinationUnknown'
                      }
                  ]
              }
          }
      }
      begin
        @ses.create_configuration_set_event_destination(event_destinaton)
      rescue Aws::SES::Errors::EventDestinationAlreadyExists
        @ses.update_configuration_set_event_destination(event_destinaton)
      end

    end

  end

end