Paperclip.interpolates :default_image_url do |attachment, style|
    'transparent.gif'
  end
  Paperclip::Attachment.default_options.merge! default_url: ':default_image_url'
  
  if ENV['FOG_DIRECTORY']
    Paperclip::Attachment.default_options.merge! storage: :s3,
    s3_credentials: {
        s3_region: ENV['AWS_S3_REGION'],
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        bucket: ENV['FOG_DIRECTORY']
    }, 
    s3_protocol: 'http',
    url: "#{Rails.env}/:class/:style_file_name.:extension",
    path: "#{Rails.env}/:class/:style_file_name.:extension"
  else
    Paperclip::Attachment.default_options.merge! url: '/static/:class/:style_file_name.:extension',
    path: ':rails_root/public/:url'
  end
  
  if ENV['S3_HOST_ALIAS']
    Paperclip::Attachment.default_options.merge! s3_host_alias: ENV['S3_HOST_ALIAS'],
    url: ':s3_alias_url', s3_protocol: 'http'
  end
  
  Paperclip.interpolates :style_file_name do |attachment, style|
    attachment.instance.style_file_name attachment, style
  end
  