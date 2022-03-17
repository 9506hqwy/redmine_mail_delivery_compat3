# frozen_string_literal: true

unless Redmine::VERSION::MAJOR >= 4
  return
end

require_dependency 'mail_delivery_compat3/issues_helper_patch'
require_dependency 'mail_delivery_compat3/listener'
require_dependency 'mail_delivery_compat3/mailer_patch'
require_dependency 'mail_delivery_compat3/wiki_extensions_comments_mailer_patch'

Redmine::Plugin.register :redmine_mail_delivery_compat3 do
  name 'Redmine Mail Delivery Compat3 plugin'
  author '9506hqwy'
  description 'This is a mail delivery Redmine3 compatible plugin for Redmine'
  version '0.1.0'
  url 'https://github.com/9506hqwy/redmine_mail_delivery_compat3'
  author_url 'https://github.com/9506hqwy'

  project_module :mail_delivery_compat3 do
    # CAUTION: not used
    permission :manage_mail_delivery_compat3, { }
  end
end
