module Sessel

  class ReceiptRule

    def initialize(region, email_addresses, s3_bucket, rule_name, rule_set_name)
      @email_addresses = email_addresses
      @region = region
      @s3_bucket = s3_bucket
      @rule_name = rule_name
      @rule_set_name = rule_set_name
    end

  end

end