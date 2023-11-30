class Language < ActiveRecord::Base

    validates_uniqueness_of :code

    scope :chinese, -> { where('code like ?', '%zh-%') }
    scope :not_chinese, -> { where('code not like ?', '%zh-%') }

    CODE_ENGLISH = 'en'
    CODE_CHINESE = 'zh-CN'

end
