require 'highline'
require 'uri'

module Sessel

  class Ask

    @@cli = HighLine.new
    @@ses = nil
    @@s3 = nil

    def self.for_region()
      region = nil
      @@cli.choose do |region_menu|
        region_menu.prompt = "Choose AWS region you want to setup SES in?"
        region_menu.choices("us-east-1", "us-west-2", "eu-west-1") { |r| region = r }
      end
      @@ses = Aws::SES::Client.new(region: region)
      @@s3 = Aws::S3::Client.new(region: region)
      return region
    end

    def self.for_rule_set_name(solution_name)
      chosen_rule_set_name = nil
      @@cli.choose do |rule_set_menu|
        solution_rule_set_name = "#{solution_name}RuleSet"
        rule_set_menu.prompt = 'Choose receipt rule-set?'
        resp = @@ses.list_receipt_rule_sets
        add_new_rule_set = true
        resp.to_h[:rule_sets].each { |rule_set|
          rule_set_menu.choice(rule_set[:name]) { chosen_rule_set_name = rule_set[:name] }
          add_new_rule_set = false if (rule_set[:name] =~ /^#{Regexp.escape(solution_rule_set_name)}$/)
        }
        rule_set_menu.choice("Create new: #{solution_rule_set_name}") {
          chosen_rule_set_name = solution_rule_set_name
        } if add_new_rule_set
      end
      return chosen_rule_set_name
    end

    def self.for_email_address()
      return @@cli.ask('What is the email address you would like to receive emails at?') {
          |q| q.validate = /\w@[a-z0-9_-].[a-z]/ }
    end

    def self.for_s3_bucket(solution_name, region)
      chosen_bucket = nil
      @@cli.choose do |s3_bucket_menu|
        solution_bucket_name = solution_name.downcase
        s3_bucket_menu.prompt = "Choose S3 bucket to put the emails in"
        resp = @@s3.list_buckets()
        add_new_bucket = true
        resp.to_h[:buckets].each { |bucket|
          s3_bucket_menu.choice(bucket[:name]) { chosen_bucket = bucket[:name] }
          add_new_bucket = false if (bucket[:name] =~ /^#{Regexp.escape(solution_bucket_name)}$/)
        }
        s3_bucket_menu.choice("Create new: #{solution_bucket_name}") {
          @@s3.create_bucket({
                                 acl: "private",
                                 bucket: solution_bucket_name,
                                 create_bucket_configuration: {
                                     location_constraint: region
                                 }
                             })
          chosen_bucket = solution_name
        } if add_new_bucket
      end
      return chosen_bucket
    end

  end

end