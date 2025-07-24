module S3FileField
  class Error < StandardError; end

  module FormBuilder
    def s3_file_field(method, options = {})
      self.multipart = true
      @template.s3_file_field(@object_name, method, objectify_options(options))
    end
  end

  module FormHelper
    def self.included(arg)
      ActionView::Helpers::FormBuilder.include S3FileField::FormBuilder
    end

    def s3_file_field(object_name, method, options = {})
      options = S3Uploader.new(options).field_options

      ActionView::Helpers::Tags::FileField.new(
        object_name, method, self, options
      ).render
    end
  end
end
