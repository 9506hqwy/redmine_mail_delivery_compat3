# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class IssuesTest < Redmine::IntegrationTest
  include ActiveJob::TestHelper
  include Redmine::I18n

  fixtures :email_addresses,
           :enabled_modules,
           :enumerations,
           :issues,
           :issue_statuses,
           :member_roles,
           :members,
           :projects,
           :projects_trackers,
           :roles,
           :user_preferences,
           :users,
           :trackers,
           :versions,
           :watchers

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['issue_added', 'issue_updated']
    ActionMailer::Base.deliveries.clear
  end

  def test_issue_add
    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 2, ActionMailer::Base.deliveries.length

    mail0 = ActionMailer::Base.deliveries[0]
    mail1 = ActionMailer::Base.deliveries[1]

    assert_equal ['jsmith@somenet.foo'], mail0.to
    assert_equal ['dlopper@somenet.foo'], mail1.to
  end

  def test_issue_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_issue_add_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    user3 = users(:users_003)
    user3.mail_notification = 'only_owner'
    user3.save!
    mem2 = members(:members_002)
    mem2.mail_notification = false
    mem2.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
              watcher_user_ids: [user3.id],
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_add_compat3_mention
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
              description: "@admin",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 3, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_issue_edit
    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/issues/2',
        params: {
          issue: {
            subject: "test issue",
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

  def test_issue_edit_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/issues/2',
        params: {
          issue: {
            subject: "test issue",
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

  def test_issue_edit_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    user3 = users(:users_003)
    user3.mail_notification = 'only_owner'
    user3.save!
    mem2 = members(:members_002)
    mem2.mail_notification = false
    mem2.save!
    issue2 = issues(:issues_002)
    issue2.watcher_user_ids << user3.id
    issue2.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/issues/2',
        params: {
          issue: {
            subject: "test issue",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_compat3_mention_description
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/issues/2',
        params: {
          issue: {
            subject: "test issue",
            description: "@admin",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 3, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def test_issue_edit_compat3_mention_notes
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/issues/2',
        params: {
          issue: {
            subject: "test issue",
            notes: "@admin",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 3, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end
end
