module Sessel

  class ReceiptRule

    def initialize(region, email_addresses, s3_bucket, rule_name, rule_set_name)
      @email_addresses = email_addresses
      @region = region
      @s3_bucket = s3_bucket
      @rule_name = rule_name
      @rule_set_name = rule_set_name
    end

    def email_addresses
      return @email_addresses
    end

    def region
      return @region
    end

    def s3_bucket
      return @s3_bucket
    end

    def rule_name
      return @rule_name
    end

    def rule_set_name
      return @rule_set_name
    end

  end

end