require 's3_file_field/version'
require 'jquery-fileupload-rails'

require 'base64'
require 'openssl'
require 'active_support/core_ext'

require 's3_file_field/config_aws'
require 's3_file_field/s3_uploader'
require 's3_file_field/form_helper'
require 's3_file_field/railtie'
require 's3_file_field/engine'

ActionView::Base.include S3FileField::FormHelper
