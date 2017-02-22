require 'uri'

module Sessel

  # Takes care of creating the receipt rule and making sure all the prerequisites are in place
  class ReceiptRuleCreator

    def initialize(region, email_addresses, s3_bucket, rule_name, rule_set_name)
      @receipt_rule = ReceiptRule.new(region, email_addresses, s3_bucket, rule_name, rule_set_name)
      @s3 = Aws::S3::Client.new(region: region)
      @sts = Aws::STS::Client.new(region: region)
      @ses = Aws::SES::Client.new(region: region)
      @route53 = Aws::Route53::Client.new(region: region)
    end

    def receipt_rule
      return @receipt_rule
    end

    # Creates the receipt rule in SES accorind to the paramteres passed when the object was initialised
    def create()

      ensure_prerequsites

      rule = {
          rule: {
              recipients: @receipt_rule.email_addresses,
              actions: [
                  {
                      s3_action: {
                          bucket_name: @receipt_rule.s3_bucket,
                          object_key_prefix: 'email',
                      },
                  },
              ],
              enabled: true,
              name: @receipt_rule.rule_name,
              scan_enabled: false,
              tls_policy: 'Optional',
          },
          rule_set_name: @receipt_rule.rule_set_name,
      }
      begin
        @ses.create_receipt_rule(rule)
      rescue Aws::SES::Errors::AlreadyExists
        @ses.update_receipt_rule(rule)
      end
    end

    private

    # Makes sure that the chosen bucket has the required policy
    def ensure_s3_bucket_policy()

      resp = @sts.get_caller_identity({})
      account = resp.to_h[:account]

      #TODO: Merge existing policies
      policy = {
          :Version => "2008-10-17",
          :Statement => [
              {
                  :Sid => "GiveSESPermissionToWriteEmail",
                  :Effect => "Allow",
                  :Principal => {
                      :Service => [
                          "ses.amazonaws.com"
                      ]
                  },
                  :Action => [
                      "s3:PutObject"
                  ],
                  :Resource => "arn:aws:s3:::#{@receipt_rule.s3_bucket}/*",
                  :Condition => {
                      :StringEquals => {
                          'aws:Referer' => account
                      }
                  }
              }
          ]
      }

      @s3.put_bucket_policy({
                                bucket: @receipt_rule.s3_bucket,
                                policy: policy.to_json
                            })
    end

    def ensure_address_domains()
      @receipt_rule.email_addresses.each { |address|
        ensure_address_domain address
      }
    end

    def ensure_address_domain(address)
      domain = address.split('@').last

      resp = @route53.list_hosted_zones_by_name({})
      hosted_zones = resp.to_h[:hosted_zones]
      hosted_zone = hosted_zones.find { |s| s[:name] == "#{domain}." }
      unless hosted_zone then
        raise Exception.new("Route53 doesn't contain domain entry for the #{domain}. If you are parking your domain outside AWS, you will need to set the DNS entries yourself")
      end
      resp = @ses.list_identities({
                                      identity_type: 'Domain'
                                  })
      identities = resp.to_h[:identities]
      domain_identity = identities.find { |s| s == domain }
      if domain_identity then
        resp = @ses.get_identity_verification_attributes({
                                                           identities: [
                                                               domain,
                                                           ]
                                                         })
        domain_identity = resp.to_h[:verification_attributes][domain]
        unless domain_identity[:verification_status] == 'Success' then
          ensure_route53_hosted_zone_entries(hosted_zone, domain_identity[:verification_token])
        end
      else
        resp = @ses.verify_domain_identity({
                                                 domain: domain,
                                             })
        verification_token = resp.to_h[:verification_token]
        ensure_route53_hosted_zone_entries(hosted_zone, verification_token)
      end
    end

    def ensure_route53_hosted_zone_entries(hosted_zone, verification_token)
      request = {
          hosted_zone_id: hosted_zone[:id],
          change_batch: {
              comment: 'Entries required for SES setup',
              changes: [
                  {
                      action: 'UPSERT',
                      resource_record_set: {
                          name: hosted_zone[:name],
                          type: 'TXT',
                          ttl: 300,
                          resource_records: [
                              {
                                  value: "\"#{verification_token}\""
                              },
                          ]
                      },
                  },
                  {
                      action: "UPSERT",
                      resource_record_set: {
                          name: hosted_zone[:name],
                          type: 'MX',
                          ttl: 300,
                          resource_records: [
                              {
                                  value: '10 inbound-smtp.eu-west-1.amazonaws.com'
                              }
                          ]
                      }
                  }
              ]
          }
      }
      resp = @route53.change_resource_record_sets(request)
    end

    # Ensure the chosen rule set exists
    def ensure_rule_set()
      resp = @ses.list_receipt_rule_sets()
      add_new_rule_set = true
      resp.to_h[:rule_sets].each { |rule_set|
        add_new_rule_set = false if (rule_set[:name] =~ /^#{Regexp.escape(@receipt_rule.rule_set_name)}$/)
      }
      @ses.create_receipt_rule_set({rule_set_name: @receipt_rule.rule_set_name}) if add_new_rule_set
    end

    # Ensure the bucket exists
    def ensure_s3_bucket()
      resp = @s3.list_buckets()
      add_new_bucket = true
      resp.to_h[:buckets].each { |bucket|
        add_new_bucket = false if (bucket[:name] =~ /^#{Regexp.escape(@receipt_rule.s3_bucket)}$/)
      }
      @s3.create_bucket({
                            acl: "private",
                            bucket: @receipt_rule.s3_bucket,
                            create_bucket_configuration: {
                                location_constraint: region
                            }
                        }) if add_new_bucket
    end

    # Execute all the assurances
    def ensure_prerequsites()

      ensure_rule_set
      ensure_s3_bucket
      ensure_s3_bucket_policy
      ensure_address_domains

    end

  end

end