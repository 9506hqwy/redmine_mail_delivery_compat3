# frozen_string_literal: true

unless Redmine::VERSION::MAJOR >= 4
  return
end

basedir = File.expand_path('../lib', __FILE__)
libraries =
  [
    'redmine_mail_delivery_compat3/issues_helper_patch',
    'redmine_mail_delivery_compat3/listener',
    'redmine_mail_delivery_compat3/mailer_patch',
    'redmine_mail_delivery_compat3/mentionable_patch',
    'redmine_mail_delivery_compat3/wiki_extensions_comments_mailer_patch',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

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
