module RedmineProjectSpecificEmailSender
  module MailerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :mail_from, :project_specific_email
        alias_method_chain :issue_add, :project_specific_email
        alias_method_chain :issue_edit, :project_specific_email
        alias_method_chain :document_added, :project_specific_email
        alias_method_chain :attachments_added, :project_specific_email
        alias_method_chain :news_added, :project_specific_email
        alias_method_chain :message_posted, :project_specific_email
      end
    end

    module InstanceMethods
      def mail_from
        Setting.mail_from
      end

      def mail(headers={})
        headers.merge! 'X-Mailer' => 'Redmine',
                'X-Redmine-Host' => Setting.host_name,
                'X-Redmine-Site' => Setting.app_title,
                'X-Auto-Response-Suppress' => 'OOF',
                'Auto-Submitted' => 'auto-generated',
                'From' => mail_from,
                'List-Id' => "<#{mail_from.to_s.gsub('@', '.')}>"

        # Removes the author from the recipients and cc
        # if he doesn't want to receive notifications about what he does
        if @author && @author.logged? && @author.pref.no_self_notified
          headers[:to].delete(@author.mail) if headers[:to].is_a?(Array)
          headers[:cc].delete(@author.mail) if headers[:cc].is_a?(Array)
        end

        if @author && @author.logged?
          redmine_headers 'Sender' => @author.login
        end

        # Blind carbon copy recipients
        if Setting.bcc_recipients?
          headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
          headers[:to] = nil
          headers[:cc] = nil
        end

        if @message_id_object
          headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
        end
        if @references_objects
          headers[:references] = @references_objects.collect {|o| "<#{self.class.message_id_for(o)}>"}.join(' ')
        end

        super headers do |format|
          format.text
          format.html unless Setting.plain_text_mail?
        end

        set_language_if_valid @initial_language
      end


      def mail_from_with_project_specific_email
        @project ? @project.email : mail_from_without_project_specific_email
      end

      def issue_add_with_project_specific_email(*args)
        @project = args.first.project
        issue_add_without_project_specific_email(*args)
      end

      def issue_edit_with_project_specific_email(*args)
        @project = args.first.journalized.project
        issue_edit_without_project_specific_email(*args)
      end

      def document_added_with_project_specific_email(*args)
        @project = args.first.project
        document_added_without_project_specific_email(*args)
      end

      def attachments_added_with_project_specific_email(*args)
        @project = args.first.first.container.project
        attachments_added_without_project_specific_email(*args)
      end

      def news_added_with_project_specific_email(*args)
        @project = args.first.project
        news_added_without_project_specific_email(*args)
      end

      def message_posted_with_project_specific_email(*args)
        @project = args.first.board.project
        message_posted_without_project_specific_email(*args)
      end
    end
  end
end
