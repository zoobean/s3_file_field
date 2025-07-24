module S3FileField
  class S3Uploader  # :nodoc:
    attr_accessor :options

    def initialize(original_options = {})

      default_options = {
        access_key_id: S3FileField.config.access_key_id,
        secret_access_key: S3FileField.config.secret_access_key,
        bucket: S3FileField.config.bucket,
        acl: "public-read",
        expiration: 10.hours.from_now.utc.iso8601,
        max_file_size: 500.megabytes,
        conditions: [],
        key_starts_with: S3FileField.config.key_starts_with || 'uploads/',
        region: S3FileField.config.region || 's3',
        url: S3FileField.config.url,
        ssl: S3FileField.config.ssl
      }

      @key = original_options[:key]
      @original_options = original_options

      # Remove s3_file_field specific options from original options
      extracted_options = @original_options.extract!(*default_options.keys).
        reject { |k, v| v.nil? }

      @options = default_options.merge(extracted_options)

      unless @options[:access_key_id]
        raise Error, "Please configure access_key_id option."
      end

      unless @options[:secret_access_key]
        raise Error, "Please configure secret_access_key option."
      end

      if @options[:bucket].nil? && @options[:url].nil?
        raise Error, "Please configure bucket name or url."
      end
    end

    def field_options
      @original_options.merge(data: field_data_options)
    end

    def field_data_options
      {
        url: url,
        key: key,
        acl: @options[:acl],
        policy: policy,
        'x-amz-algorithm': 'AWS4-HMAC-SHA256',
        'x-amz-credential': credential,
        'x-amz-date': iso_date,
        'x-amz-signature': signature
      }.merge(@original_options[:data] || {})
    end

    private

    def key
      @key ||= "#{@options[:key_starts_with]}{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}"
    end

    def url
      @url ||=
        if @options[:url]
          @options[:url]
        else
          protocol = @options[:ssl] == true ? "https" : @options[:ssl] == false ? "http" : nil
          subdomain = "#{@options[:bucket]}.#{@options[:region]}"
          domain = "//#{subdomain}.amazonaws.com/"
          [protocol, domain].compact.join(":")
        end
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", '')
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          ["starts-with", "$key", @options[:key_starts_with]],
          ["starts-with", "$x-requested-with", ""],
          ["content-length-range", 0, @options[:max_file_size]],
          ["starts-with","$Content-Type",""],
          {bucket: @options[:bucket]},
          {acl: @options[:acl]},
          {success_action_status: "201"},
          {"x-amz-algorithm": "AWS4-HMAC-SHA256"},
          {"x-amz-credential": credential},
          {"x-amz-date": iso_date}
        ] + @options[:conditions]
      }
    end

    def signature
      signing_key = get_signature_key(@options[:secret_access_key], date_stamp, @options[:region], 's3')
      OpenSSL::HMAC.hexdigest('sha256', signing_key, policy)
    end

    def credential
      "#{@options[:access_key_id]}/#{date_stamp}/#{@options[:region]}/s3/aws4_request"
    end

    def iso_date
      @iso_date ||= Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
    end

    def date_stamp
      @date_stamp ||= Time.now.utc.strftime('%Y%m%d')
    end

    def get_signature_key(key, date_stamp, region_name, service_name)
      k_date = OpenSSL::HMAC.digest('sha256', "AWS4#{key}", date_stamp)
      k_region = OpenSSL::HMAC.digest('sha256', k_date, region_name)
      k_service = OpenSSL::HMAC.digest('sha256', k_region, service_name)
      k_signing = OpenSSL::HMAC.digest('sha256', k_service, 'aws4_request')
      k_signing
    end
  end
end
