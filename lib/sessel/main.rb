require 'thor'
require 'aws-sdk'
require 'json'
require 'yaml'

module Sessel

  SESSEL_YAML = 'sessel.yaml'

  class Add < Thor

    no_commands {
      def announce()
        puts 'Question:'
        ret = yield
        puts "Answer: #{ret}\n\n"
        return ret
      end
    }

    option :interactive, :type => :boolean
    desc "receipt_rule SOLUTION_NAME", "Start setup of SES for your particular SOLUTION_NAME"
    long_desc <<-LONGDESC
      Adds a new configuration item into the configuration.
    LONGDESC
    def receipt_rule(solution_name)
      if (options[:interactive]) then
        region = announce { Ask.for_region }
        chosen_rule_set_name = announce { Ask.for_rule_set_name(solution_name) }
        email_address = announce { Ask.for_email_address }
        s3_bucket = announce { Ask.for_s3_bucket(solution_name) }
        rule_creator = Sessel::ReceiptRuleCreator.new(region, [email_address], s3_bucket, solution_name, chosen_rule_set_name)
        rule_creator.create

        puts "That's it!"
        config = {}
        if File.file?(SESSEL_YAML) then
          config = YAML.load  File.read(SESSEL_YAML);
        end
        unless config[:receipt_rules] then
          config[:receipt_rules] = []
        end
        config[:receipt_rules].push(rule_creator.receipt_rule)
        File.open(SESSEL_YAML, 'w') { |file| file.write(config.to_yaml) }
      else
        puts 'Non interactive not implemented'
      end
    end
  end

  class Main < Thor

    option :interactive, :type => :boolean
    desc 'apply', 'Uses the sessle.yaml to providsion resources in the AWS account'
    long_desc <<-LONGDESC
      Uses the configuration stored in sessle.yaml to provision or uptate the recourses in the AWS account
    LONGDESC
    def apply
        puts 'Non implemented'
    end

    desc 'add SUBCOMMAND ...ARGS', 'Add configuration items to the sessle.yaml.'
    subcommand 'add', Add

  end
end