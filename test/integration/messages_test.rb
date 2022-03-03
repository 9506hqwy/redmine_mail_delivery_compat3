# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class MessagesTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :boards,
           :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :messages,
           :projects,
           :roles,
           :user_preferences,
           :users,
           :watchers

  def setup
    Setting.bcc_recipients = false
    Setting.notified_events = ['message_posted']
    ActionMailer::Base.deliveries.clear
  end

  def test_message_posted
    log_user('admin', 'admin')

    new_record(Message) do
      post(
        '/boards/1/topics/new',
        params: {
          message: {
            subject: 'test',
            content: 'test',
          }
        })
    end

    assert_equal 3, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries[0].to.length
    assert_equal 1, ActionMailer::Base.deliveries[1].to.length
    assert_equal 1, ActionMailer::Base.deliveries[2].to.length

    to0 = ActionMailer::Base.deliveries[0].to
    to1 = ActionMailer::Base.deliveries[1].to
    to2 = ActionMailer::Base.deliveries[2].to

    assert_include 'admin@somenet.foo', (to0 + to1 + to2)
    assert_include 'jsmith@somenet.foo', (to0 + to1 + to2)
    assert_include 'dlopper@somenet.foo', (to0 + to1 + to2)
  end

  def test_message_posted_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    new_record(Message) do
      post(
        '/boards/1/topics/new',
        params: {
          message: {
            subject: 'test',
            content: 'test',
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_message_posted_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    b = boards(:boards_001)
    b.add_watcher(users(:users_004))
    b.save!

    log_user('admin', 'admin')

    new_record(Message) do
      post(
        '/boards/1/topics/new',
        params: {
          message: {
            subject: 'test',
            content: 'test',
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'rhill@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end
end
