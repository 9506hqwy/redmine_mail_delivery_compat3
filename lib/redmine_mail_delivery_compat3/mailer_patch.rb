# frozen_string_literal: true

module RedmineMailDeliveryCompat3
  module MailerClassPatch
    def deliver_issue_add(issue)
      project = issue.project
      if mail_delivery_compat3_enable_module?(project)
        users = issue.notified_users | issue.notified_watchers
        users |= issue.notified_mentions if mail_delivery_compat3_enable_mention
        issue_add(users, issue).deliver_later
      else
        super
      end
    end

    def deliver_issue_edit(journal)
      project = journal.project
      if mail_delivery_compat3_enable_module?(project)
        users  = journal.notified_users | journal.notified_watchers
        users |= journal.notified_mentions if mail_delivery_compat3_enable_mention
        users |= journal.journalized.notified_mentions if mail_delivery_compat3_enable_mention
        users.select! do |user|
          journal.notes? || journal.visible_details(user).any?
        end
        issue_edit(users, journal).deliver_later
      else
        super
      end
    end

    def deliver_document_added(document, author)
      project = document.project
      if mail_delivery_compat3_enable_module?(project)
        users = document.notified_users
        document_added(users, document, author).deliver_later
      else
        super
      end
    end

    def deliver_attachments_added(attachments)
      container = attachments.first.container
      project = container.project

      if mail_delivery_compat3_enable_module?(project)
        case container.class.name
        when 'Project', 'Version'
          users = project.notified_users.select {|user| user.allowed_to?(:view_files, project)}
        when 'Document'
          users = container.notified_users
        end

        attachments_added(users, attachments).deliver_later
      else
        super
      end
    end

    def deliver_news_added(news)
      project = news.project
      if mail_delivery_compat3_enable_module?(project)
        users = news.notified_users | news.notified_watchers_for_added_news
        news_added(users, news).deliver_later
      else
        super
      end
    end

    def deliver_news_comment_added(comment)
      news = comment.commented
      project = news.project
      if mail_delivery_compat3_enable_module?(project)
        users = news.notified_users | news.notified_watchers
        news_comment_added(users, comment).deliver_later
      else
        super
      end
    end

    def deliver_message_posted(message)
      project = message.board.project
      if mail_delivery_compat3_enable_module?(project)
        users  = message.notified_users
        users |= message.root.notified_watchers
        users |= message.board.notified_watchers
        message_posted(users, message).deliver_later
      else
        super
      end
    end

    def deliver_wiki_content_added(wiki_content)
      project = wiki_content.page.wiki.project
      if mail_delivery_compat3_enable_module?(project)
        users = wiki_content.notified_users | wiki_content.page.wiki.notified_watchers
        users |= wiki_content.notified_mentions if mail_delivery_compat3_enable_mention
        wiki_content_added(users, wiki_content).deliver_later
      else
        super
      end
    end

    def deliver_wiki_content_updated(wiki_content)
      project = wiki_content.page.wiki.project
      if mail_delivery_compat3_enable_module?(project)
        users  = wiki_content.notified_users
        users |= wiki_content.page.notified_watchers
        users |= wiki_content.page.wiki.notified_watchers
        users |= wiki_content.notified_mentions if mail_delivery_compat3_enable_mention
        wiki_content_updated(users, wiki_content).deliver_later
      else
        super
      end
    end

    def mail_delivery_compat3_enable_mention
      Redmine::VERSION::MAJOR >= 5
    end

    private

    def mail_delivery_compat3_enable_module?(project)
      project.module_enabled?(:mail_delivery_compat3)
    end
  end

  module MailerPatch
    def process(action, *args)
      user = args.first
      if mail_delivery_methods.include?(action) && !user.is_a?(User)
        # Limitation: Use current user language.
        self.class.superclass.instance_method(:process).bind(self).call(action, *args)
      else
        super
      end
    end

    def mail(headers={}, &block)
      if @user && @user.is_a?(Enumerable)
        # does not contain user.id in `token_for`.
        @user = nil

        mail_delivery_compat3_classify_recipients(headers)
      end

      super
    end

    private

    def mail_delivery_compat3_classify_recipients(headers)
      users = headers[:to]
      return if users.blank?

      if @journal # issue_edit
        to = @journal.notified_users
        if self.class.mail_delivery_compat3_enable_mention
          @journal.mail_delivery_compat3_parse_mentions_for_issue_edit
          to |= @journal.notified_mentions
          to |= @journal.journalized.notified_mentions
        end
        to &= users
        cc = (users & @journal.notified_watchers) - to
        headers[:to] = to
        headers[:cc] = cc
      elsif @issue # issue_add
        to = @issue.notified_users
        if self.class.mail_delivery_compat3_enable_mention
          @issue.mail_delivery_compat3_parse_mentions_for_issue_add
          to |= @issue.notified_mentions
        end
        to &= users
        cc = (users & @issue.notified_watchers) - to
        headers[:to] = to
        headers[:cc] = cc
      elsif @document # document_added
        # pass
      elsif @attachments # attachments_added
        # pass
      elsif @comment # news_comment_added
        to = users & @news.notified_users
        cc = (users & @news.notified_watchers) - to
        headers[:to] = to
        headers[:cc] = cc
      elsif @news # news_added
        to = users & @news.notified_users
        cc = (users & @news.notified_watchers_for_added_news) - to
        headers[:to] = to
        headers[:cc] = cc
      elsif @message && @message.is_a?(Message) # message_posted
        to = users & @message.notified_users
        cc = @message.root.notified_watchers
        cc |= @message.board.notified_watchers
        cc &= users
        cc -= to
        headers[:to] = to
        headers[:cc] = cc
      elsif @wiki_content # wiki_content_added / wiki_content_updated
        to = @wiki_content.notified_users
        if self.class.mail_delivery_compat3_enable_mention
          @wiki_content.mail_delivery_compat3_parse_mentions_for_wiki_content
          to |= @wiki_content.notified_mentions
        end
        to &= users
        cc = @wiki_content.page.wiki.notified_watchers
        cc |= @wiki_content.page.notified_watchers
        cc &= users
        cc -= to
        headers[:to] = to
        headers[:cc] = cc
      end
    end

    def mail_delivery_methods
      [
        :issue_add,
        :issue_edit,
        :document_added,
        :attachments_added,
        :news_added,
        :news_comment_added,
        :message_posted,
        :wiki_content_added,
        :wiki_content_updated,
      ]
    end
  end
end

Mailer.singleton_class.prepend RedmineMailDeliveryCompat3::MailerClassPatch
Mailer.prepend RedmineMailDeliveryCompat3::MailerPatch
