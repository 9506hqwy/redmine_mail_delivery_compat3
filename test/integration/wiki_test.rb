# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class WikiTest < Redmine::IntegrationTest
  include ActiveJob::TestHelper
  include Redmine::I18n

  fixtures :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :projects,
           :roles,
           :user_preferences,
           :users,
           :watchers,
           :wiki_content_versions,
           :wiki_contents,
           :wiki_pages,
           :wikis

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['wiki_content_added', 'wiki_content_updated', 'wiki_comment_added']
    ActionMailer::Base.deliveries.clear
  end

  def test_wiki_content_added
    log_user('admin', 'admin')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
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

  def test_wiki_content_added_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_wiki_content_added_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    wiki = wikis(:wikis_001)
    wiki.add_watcher(users(:users_004))
    wiki.save!

    log_user('admin', 'admin')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'rhill@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_wiki_content_updated
    log_user('admin', 'admin')

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    assert_equal 2, ActionMailer::Base.deliveries.length

    mail0 = ActionMailer::Base.deliveries[0]
    mail1 = ActionMailer::Base.deliveries[1]

    assert_equal ['jsmith@somenet.foo'], mail0.to
    assert_equal ['dlopper@somenet.foo'], mail1.to
  end

  def test_wiki_content_updated_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('admin', 'admin')

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_wiki_content_updated_compat3_watcher
    Project.find(1).enable_module!(:mail_delivery_compat3)

    wiki = wikis(:wikis_001)
    wiki.add_watcher(users(:users_004))
    wiki.save!

    log_user('admin', 'admin')

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
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

  def test_wiki_comment_added
    skip unless Redmine::Plugin.installed?(:redmine_wiki_extensions)

    Project.find(1).enable_module!(:wiki_extensions)
    Role.find(1).add_permission!(:add_wiki_comment)

    page = wiki_pages(:wiki_pages_001)
    page.add_watcher(users(:users_001))

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      post(
        '/projects/ecookbook/wiki_extensions/add_comment',
        params: {
          wiki_page_id: page.id,
          comment: 'test comment',
        })
    end

    assert_equal 3, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries[0].to.length
    assert_equal 1, ActionMailer::Base.deliveries[1].to.length
    assert_equal 1, ActionMailer::Base.deliveries[2].to.length

    t0 = ActionMailer::Base.deliveries[0].to
    t1 = ActionMailer::Base.deliveries[1].to
    t2 = ActionMailer::Base.deliveries[2].to

    assert_include 'admin@somenet.foo', (t0 + t1 + t2)
    assert_include 'jsmith@somenet.foo', (t0 + t1 + t2)
    assert_include 'dlopper@somenet.foo', (t0 + t1 + t2)
  end

  def test_wiki_comment_added_compat3
    skip unless Redmine::Plugin.installed?(:redmine_wiki_extensions)

    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:wiki_extensions)
    Role.find(1).add_permission!(:add_wiki_comment)

    page = wiki_pages(:wiki_pages_001)
    page.add_watcher(users(:users_001))

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      post(
        '/projects/ecookbook/wiki_extensions/add_comment',
        params: {
          wiki_page_id: page.id,
          comment: 'test comment',
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 3, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end
end
