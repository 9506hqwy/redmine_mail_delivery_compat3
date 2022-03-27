# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DocumentsTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :documents,
           :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :projects,
           :roles,
           :user_preferences,
           :users,
           :watchers

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['document_added']
    ActionMailer::Base.deliveries.clear
  end

  def test_document_add
    log_user('admin', 'admin')

    new_record(Document) do
      post(
        '/projects/ecookbook/documents',
        params: {
          document: {
            title: 'test',
            description: 'test',
            category_id: "1",
          }
        })
    end

    assert_equal 2, ActionMailer::Base.deliveries.length

    mail0 = ActionMailer::Base.deliveries[0]
    mail1 = ActionMailer::Base.deliveries[1]

    assert_equal ['jsmith@somenet.foo'], mail0.to
    assert_equal ['dlopper@somenet.foo'], mail1.to
  end

  def test_document_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    new_record(Document) do
      post(
        '/projects/ecookbook/documents',
        params: {
          document: {
            title: 'test',
            description: 'test',
            category_id: "1",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end
end
