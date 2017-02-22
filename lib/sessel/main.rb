require 'thor'
require 'highline'
require 'aws-sdk'
require 'json'
require 'yaml'

module Sessel
  
  class Main < Thor

    no_commands {
      def announce()
        puts 'Question:'
        ret = yield
        puts "Answer: #{ret}\n\n"
        return ret
      end
    }

    option :interactive, :type => :boolean
    desc "setup SOLUTION_NAME", "Start setup of SES for yourr particular SOLUTION_NAME"
    def setup(solution_name)
      if (options[:interactive]) then

          region = announce { Ask.for_region }
          chosen_rule_set_name = announce { Ask.for_rule_set_name(solution_name) }
          email_address = announce {  Ask.for_email_address }
          s3_bucket = announce { Ask.for_s3_bucket(solution_name) }
          rule_creator = Sessel::ReceiptRule.new(region, [email_address], s3_bucket, solution_name, chosen_rule_set_name)
          rule_creator.create

          puts "That's it!"
          p rule_creator.to_yaml_properties
          puts [rule_creator.receipt_rule].to_yaml
      else
          puts 'Non interactive not implemented'
      end
    end
  end
end