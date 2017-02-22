require 'thor'
require 'aws-sdk'
require 'json'
require 'yaml'

module Sessel

  SESSEL_YAML = 'sessel.yaml'

  class Add < Thor

    desc "receipt_rule SOLUTION_NAME", "Start setup of SES receipt rule for your particular SOLUTION_NAME"
    long_desc <<-LONGDESC
      Adds a new receipt rule to the configuration.
    LONGDESC
    def receipt_rule(solution_name)
      region = IO.announce { Ask.for_region }
      chosen_rule_set_name = IO.announce { Ask.for_rule_set_name(solution_name) }
      email_address = IO.announce { Ask.for_email_address }
      s3_bucket = IO.announce { Ask.for_s3_bucket(solution_name, region) }
      rule_creator = Sessel::ReceiptRuleCreator.new(
          ReceiptRule.new(region, [email_address], s3_bucket, solution_name, chosen_rule_set_name)
      )
      rule_creator.create
      IO.append_receipt_rule_to_file(rule_creator.receipt_rule)
      puts "That's it!"
    end

    desc "configuration_set SOLUTION_NAME", "Start setup of SES configuration set for your particular SOLUTION_NAME"
    long_desc <<-LONGDESC
      Adds a new configuration set into the configuration.
    LONGDESC
    def configuration_set(solution_name)
      region = IO.announce { Ask.for_region }
      configuration_set_creator = Sessel::ConfigurationSetCreator.new(
          ConfigurationSet.new(region, "#{solution_name}ConfigurationSet")
      )
      configuration_set_creator.create
      IO.append_configuration_set_to_file(configuration_set_creator.configuration_set)
      puts "That's it!"
    end
  end

  class Main < Thor

    option :interactive, :type => :boolean
    desc 'apply', 'Uses the sessle.yaml to providsion resources in the AWS account'
    long_desc <<-LONGDESC
      Uses the configuration stored in sessle.yaml to provision or uptate the recourses in the AWS account
    LONGDESC
    def apply
        config = IO.read_config_from_file
        config[:receipt_rules].each do |receipt_rule|
          puts "Applying receipt rule: #{receipt_rule.rule_set_name} / #{receipt_rule.rule_name}"
          rule_creator = Sessel::ReceiptRuleCreator.new(receipt_rule)
          rule_creator.create
        end
        config[:configuration_sets].each do |configuration_set|
          puts "Applying configuration set: #{configuration_set.configuration_set_name}"
          configuration_set_creator = Sessel::ConfigurationSetCreator.new(configuration_set)
          configuration_set_creator.create
        end
        puts 'Done'
    end

    desc 'add SUBCOMMAND ...ARGS', 'Add configuration items to the sessle.yaml.'
    subcommand 'add', Add

  end
end