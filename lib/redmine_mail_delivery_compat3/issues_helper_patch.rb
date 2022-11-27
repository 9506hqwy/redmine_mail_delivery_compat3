# frozen_string_literal: true

module RedmineMailDeliveryCompat3
  module IssuesHelperPatch
    def email_issue_attributes(issue, user, html)
      if issue.project.module_enabled?(:mail_delivery_compat3)
        email_issue_attributes_for_allusers(issue, html)
      else
        super
      end
    end

    private

    def email_issue_attributes_for_allusers(issue, html)
      items = []
      %w(author status priority assigned_to category fixed_version start_date due_date).each do |attribute|
        if issue.disabled_core_fields.grep(/^#{attribute}(_id)?$/).empty?
          attr_value = (issue.send attribute).to_s
          next if attr_value.blank?

          if html
            items << content_tag('strong', "#{l("field_#{attribute}")}: ") + attr_value
          else
            items << "#{l("field_#{attribute}")}: #{attr_value}"
          end
        end
      end
      issue.custom_field_values.each do |value|
        # Limitation: only "to any users".
        next unless value.custom_field.roles.empty?

        cf_value = show_value(value, false)
        next if cf_value.blank?

        if html
          items << content_tag('strong', "#{value.custom_field.name}: ") + cf_value
        else
          items << "#{value.custom_field.name}: #{cf_value}"
        end
      end
      items
    end
  end
end

Rails.application.config.after_initialize do
  Mailer.send(:helper, RedmineMailDeliveryCompat3::IssuesHelperPatch)
end
