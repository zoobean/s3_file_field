//= require jquery-fileupload/basic
//= require jquery-fileupload/vendor/tmpl

(function($) {
  'use strict';

  $.fn.S3FileField = function(options = {}) {
    // Support multiple elements
    if (this.length > 1) {
      this.each((_, element) => {
        $(element).S3FileField(options);
      });
      return this;
    }

    const $this = this;
    
    const extractOption = (key) => {
      const extracted = options[key];
      delete options[key];
      return extracted;
    };

    const getFormData = (data, form) => {
      if (typeof data === 'function') {
        return data(form);
      }
      
      if (Array.isArray(data)) {
        return data;
      }
      
      if (typeof data === 'object' && data !== null) {
        const formData = [];
        Object.entries(data).forEach(([name, value]) => {
          formData.push({ name, value });
        });
        return formData;
      }
      
      return [];
    };

    const url = extractOption('url');
    const add = extractOption('add');
    const done = extractOption('done');
    const fail = extractOption('fail');
    const extraFormData = extractOption('formData');

    delete options.paramName;
    delete options.singleFileUploads;

    const finalFormData = {};

    const isIE9OrBelow = (() => {
      const userAgent = navigator.userAgent.toLowerCase();
      const msie = /msie/.test(userAgent) && !/opera/.test(userAgent);
      const msieVersion = parseInt((userAgent.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/) || [])[1], 10);
      return msie && msieVersion <= 9;
    })();

    const settings = {
      // File input name must be "file"
      paramName: 'file',

      // S3 doesn't support multiple file uploads
      singleFileUploads: true,

      // We don't want to send it to default form url
      url: url || $this.data('url'),

      // For IE <= 9 force iframe transport
      forceIframeTransport: isIE9OrBelow,

      add(e, data) {
        data.files[0].unique_id = Math.random().toString(36).substring(2, 18);
        if (add) {
          add(e, data);
        } else {
          data.submit();
        }
      },

      done(e, data) {
        data.result = buildContentObject(data.files[0], data.result);
        if (done) {
          done(e, data);
        }
      },

      fail(e, data) {
        if (fail) {
          fail(e, data);
        }
      },

      formData() {
        const file = this.files[0];
        const uniqueId = file.unique_id;
        
        finalFormData[uniqueId] = {
          key: $this.data('key')
            .replace('{timestamp}', new Date().getTime())
            .replace('{unique_id}', uniqueId),
          'Content-Type': file.type,
          acl: $this.data('acl'),
          policy: $this.data('policy'),
          'x-amz-algorithm': $this.data('x-amz-algorithm'),
          'x-amz-credential': $this.data('x-amz-credential'),
          'x-amz-date': $this.data('x-amz-date'),
          'x-amz-signature': $this.data('x-amz-signature'),
          success_action_status: '201',
          'X-Requested-With': 'xhr'
        };

        return getFormData(finalFormData[uniqueId]).concat(getFormData(extraFormData));
      }
    };

    Object.assign(settings, options);

    const toS3Filename = (filename) => {
      const trimmed = filename.replace(/^\s+|\s+$/g, '');
      const stripBeforeSlash = trimmed.split('\\').slice(-1)[0];
      const doubleEncodeQuote = stripBeforeSlash.replace('"', '%22');
      return encodeURIComponent(doubleEncodeQuote);
    };

    const buildContentObject = (file, result) => {
      const content = {};

      if (result) {
        // Use the S3 response to set the URL to avoid character encodings bugs
        content.url = $(result)
          .find('Location')
          .text()
          .replace(/%2F/gi, '/')
          .replace('http:', 'https:');
        content.filepath = $('<a />').attr('href', content.url)[0].pathname;
      } else {
        // IE <= 9 returns null result so hack is necessary
        const domain = settings.url
          .replace(/\/+$/, '')
          .replace(/^(https?:)?/, 'https:');
        content.filepath = finalFormData[file.unique_id].key
          .replace('/${filename}', '');
        content.url = `${domain}/${content.filepath}/${toS3Filename(file.name)}`;
      }

      content.filename = file.name;
      
      if ('size' in file) {
        content.filesize = file.size;
      }
      
      if ('type' in file) {
        content.filetype = file.type;
      }
      
      if ('unique_id' in file) {
        content.unique_id = file.unique_id;
      }

      return content;
    };

    return $this.fileupload(settings);
  };

})(jQuery);