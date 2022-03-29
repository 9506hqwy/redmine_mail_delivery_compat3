# frozen_string_literal: true

module RedmineMailDeliveryCompat3
  class Listener < Redmine::Hook::Listener
    def after_plugins_loaded(context)
      plugin = Redmine::Plugin.find(:redmine_wiki_extensions)
      version = plugin.version.split('.').map(&:to_i)
      if ([0, 9, 3] <=> version) <= 0
        WikiExtensionsCommentsMailer.singleton_class.prepend WikiExtensionsCommentsMailerClassPatch
        WikiExtensionsCommentsMailer.prepend WikiExtensionsCommentsMailerPatch
      end
    rescue Redmine::PluginNotFound
      # PASS
    end
  end
end
