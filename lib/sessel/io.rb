module Sessel

  class IO

    def self.announce()
      puts 'Question:'
      ret = yield
      puts "Answer: #{ret}\n\n"
      return ret
    end

    def self.read_config_from_file()
      config = {}
      if File.file?(SESSEL_YAML) then
        config = YAML.load  File.read(SESSEL_YAML);
      end
      unless config[:receipt_rules] then
        config[:receipt_rules] = []
      end
      return config
    end

    def self.append_rule_to_file(receipt_rule)
      config = read_config_from_file
      config[:receipt_rules].push(receipt_rule)
      File.open(SESSEL_YAML, 'w') { |file| file.write(config.to_yaml) }
    end

  end
end