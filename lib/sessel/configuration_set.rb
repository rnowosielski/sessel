module Sessel

  class ConfigurationSet

    def initialize(region, configuration_set_name)
      @configuration_set_name = configuration_set_name
      @region = region
    end

    def configuration_set_name
      return @configuration_set_name
    end

    def region
      return @region
    end

  end

end