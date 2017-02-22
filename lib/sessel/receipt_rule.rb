module Sessel

  # Takes care of creating the receipt rule and making sure all the prerequisites are in place
  class ReceiptRule

    def initialize(region, email_addresses, s3_bucket, rule_name, rule_set_name)
      @email_addresses = email_addresses
      @region = region
      @s3_bucket = s3_bucket
      @rule_name = rule_name
      @rule_set_name = rule_set_name

      @s3 = Aws::S3::Client.new(region: @region)
      @sts = Aws::STS::Client.new(region: @region)
    end

    # Creates the receipt rule in SES accorind to the paramteres passed when the object was initialised
    def create()

      self.ensure_prerequsites

      ses = Aws::SES::Client.new(region: @region)
      ses.create_receipt_rule({
                                  rule: {
                                      recipients: @email_addresses,
                                      actions: [
                                          {
                                              s3_action: {
                                                  bucket_name: @s3_bucket,
                                                  object_key_prefix: 'email',
                                              },
                                          },
                                      ],
                                      enabled: true,
                                      name: @rule_name,
                                      scan_enabled: false,
                                      tls_policy: 'Optional',
                                  },
                                  rule_set_name: @rule_set_name,
                              })
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
                  :Resource => "arn:aws:s3:::#{chosen_bucket}/*",
                  :Condition => {
                      :StringEquals => {
                          'aws:Referer' => account
                      }
                  }
              }
          ]
      }
      puts policy.to_json
      @s3.put_bucket_policy({
                                bucket: chosen_bucket,
                                policy: policy.to_json
                            })
    end

    # Ensure the chosen rule set exists
    def ensure_rule_set()
      resp = @ses.list_receipt_rule_sets()
      add_new_rule_set = true
      resp.to_h[:rule_sets].each { |rule_set|
        add_new_rule_set = false if (rule_set[:name] =~ /^#{Regexp.escape(@rule_set_name)}$/)
      }
      @ses.create_receipt_rule_set({rule_set_name: solution_rule_set_name}) if add_new_rule_set
    end

    # Ensure the bucket exists
    def ensure_s3_bucket()
      resp = @s3.list_buckets()
      add_new_bucket = true
      resp.to_h[:buckets].each { |bucket|
        add_new_bucket = false if (bucket[:name] =~ /^#{Regexp.escape(@s3_bucket)}$/)
      }
      @s3.create_bucket({
                            acl: "private",
                            bucket: solution_bucket_name,
                            create_bucket_configuration: {
                                location_constraint: region
                            }
                        }) if add_new_bucket
    end

    # Execute all the assurances
    def ensure_prerequsites()

      self.ensure_rule_set
      self.ensure_s3_bucket
      self.ensure_s3_bucket_policy

    end

  end

end