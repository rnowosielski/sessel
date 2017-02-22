require "thor"
require "highline"
require "aws-sdk"
require 'json'

module Sessel
  class Main < Thor
    option :interactive, :type => :boolean
    desc "setup SOLUTION_NAME", "Start setup of SES for yourr particular SOLUTION_NAME"
    def setup(solution_name)
      if (options[:interactive]) then
        cli = HighLine.new
          region = nil
          cli.choose do |region_menu|
            region_menu.prompt = "Choose AWS region you want to setup SES in?"
            region_menu.choices("us-east-1", "us-west-2", "eu-west-1") { |r| region = r }
          end
          puts "You have chosen #{region}"
          ses = Aws::SES::Client.new(region: region)
          chosen_rule_set_name = nil

          cli.choose do |rule_set_menu|
            rule_set_menu.prompt = "Choose receipt rule-set?"
            resp = ses.list_receipt_rule_sets()
            add_new_rule_set = true
            resp.to_h[:rule_sets].each { |rule_set|
              rule_set_menu.choice(rule_set[:name]) { chosen_rule_set_name = rule_set[:name] }
              add_new_rule_set = false if (rule_set[:name] =~ /^#{Regexp.escape(solution_name)}$/)
            }
            rule_set_menu.choice("Create new: #{solution_name}") {
              ses.create_receipt_rule_set({ rule_set_name: solution_name })
              chosen_rule_set_name = solution_name
            } if add_new_rule_set
          end
          puts "You have chosen #{chosen_rule_set_name}"
          email_address = cli.ask "What is the email address you would like to receive emails at?"

          s3 = Aws::S3::Client.new(region: region)
          chosen_bucket = solution_name
          cli.choose do |s3_bucket_menu|
            solution_bucket_name = solution_name.downcase
            s3_bucket_menu.prompt = "Choose S3 bucket to put the emails in"
            resp = s3.list_buckets()
            add_new_bucket = true
            resp.to_h[:buckets].each { |bucket|
              s3_bucket_menu.choice(bucket[:name]) { chosen_bucket = bucket[:name] }
              add_new_bucket = false if (bucket[:name] =~ /^#{Regexp.escape(solution_bucket_name)}$/)
            }
            s3_bucket_menu.choice("Create new: #{solution_bucket_name}") {
              s3.create_bucket({
                  acl: "private",
                  bucket: solution_bucket_name,
                  create_bucket_configuration: {
                      location_constraint: region
                  }
              })
              chosen_bucket = solution_name
            } if add_new_bucket
          end

          sts = Aws::STS::Client.new(region: region)
          resp = sts.get_caller_identity({})
          account = resp.to_h["account"]

          policy = {
            Version: "2008-10-17",
            Statement: [
              {
                Sid: "GiveSESPermissionToWriteEmail",
                Effect: "Allow",
                Principal: {
                Service: [
                  "ses.amazonaws.com"
                ]
              },
              Action: [
                "s3:PutObject"
              ],
              Resource: "arn:aws:s3:::#{chosen_bucket}/*",
              Condition: {
                StringEquals: {
                  "aws:Referer" => "ACCOUNT-ID-WITHOUT-HYPHENS"
                }
              }
              }
            ]
          }
          s3.put_bucket_policy({
            bucket: chosen_bucket,
            policy: policy.to_json
          })

          resp = ses.create_receipt_rule({
            after: "",
            rule: {
              recipients: [ email_address ],
              actions: [
                {
                  s3_action: {
                      bucket_name: chosen_bucket,
                      object_key_prefix: "email",
                  },
                },
              ],
              enabled: true,
              name: solution_name,
              scan_enabled: true,
              tls_policy: "Optional",
            },
            rule_set_name: chosen_rule_set_name,
         })
         puts resp.to_h
        end
      end
  end
end