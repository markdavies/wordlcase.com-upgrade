
if ENV['SEED_ADMIN_EMAIL'] && ENV['SEED_ADMIN_PASSWORD']
  AdminUser.create email: ENV['SEED_ADMIN_EMAIL'], password: ENV['SEED_ADMIN_PASSWORD'], auth_level: 'admin'
end

Language.find_or_create_by({code: 'en', name: 'English'})
Language.find_or_create_by({code: 'fr', name: 'French'})
Language.find_or_create_by({code: 'it', name: 'Italian'})
Language.find_or_create_by({code: 'de', name: 'German'})
Language.find_or_create_by({code: 'es', name: 'Spanish'})
Language.find_or_create_by({code: 'ja', name: 'Japanese'})
Language.find_or_create_by({code: 'ko', name: 'Korean'})
Language.find_or_create_by({code: 'ru', name: 'Russian'})
Language.find_or_create_by({code: 'tr', name: 'Turkish'})
Language.find_or_create_by({code: 'ar', name: 'Arabic'})
Language.find_or_create_by({code: 'pt-BR', name: 'Brazilian Portuguese'})
Language.find_or_create_by({code: 'nl', name: 'Dutch'})