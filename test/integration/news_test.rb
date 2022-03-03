# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class NewssTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :comments,
           :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :news,
           :projects,
           :roles,
           :user_preferences,
           :users,
           :watchers

  def setup
    Setting.bcc_recipients = false
    Setting.notified_events = ['news_added', 'news_comment_added']
    ActionMailer::Base.deliveries.clear
  end

  def test_news_add
    log_user('admin', 'admin')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 2, ActionMailer::Base.deliveries.length

    mail0 = ActionMailer::Base.deliveries[0]
    mail1 = ActionMailer::Base.deliveries[1]

    assert_equal ['jsmith@somenet.foo'], mail0.to
    assert_equal ['dlopper@somenet.foo'], mail1.to
  end

  def test_news_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_news_add_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    m = Project.find(1).enabled_module(:news)
    m.add_watcher(users(:users_004))
    m.save!

    log_user('admin', 'admin')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'rhill@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_news_comment_add
    log_user('admin', 'admin')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 2, ActionMailer::Base.deliveries.length

    mail0 = ActionMailer::Base.deliveries[0]
    mail1 = ActionMailer::Base.deliveries[1]

    assert_equal ['jsmith@somenet.foo'], mail0.to
    assert_equal ['dlopper@somenet.foo'], mail1.to
  end

  def test_news_comment_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_news_comment_add_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    n = news(:news_001)
    n.add_watcher(users(:users_004))
    n.save!

    log_user('admin', 'admin')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'rhill@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end
end
