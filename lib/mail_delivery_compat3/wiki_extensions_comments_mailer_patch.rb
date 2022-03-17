# frozen_string_literal: true

module RedmineMailDeliveryCompat3
  module WikiExtensionsCommentsMailerClassPatch
    def deliver_wiki_commented(comment, wiki_page)
      project = wiki_page.project
      if mail_delivery_compat3_enable_module?(project)
        users = wiki_page.watchers.map { |watcher| watcher.user } | wiki_page.content.notified_users
        wiki_commented(users, comment, wiki_page).deliver_now
      else
        super
      end
    end
  end

  module WikiExtensionsCommentsMailerPatch
    def process(action, *args)
      user = args.first
      if !user.is_a?(User)
        # Limitation: Use current user language.
        self.class.superclass.superclass.instance_method(:process).bind(self).call(action, *args)
      else
        super
      end
    end
  end
end
