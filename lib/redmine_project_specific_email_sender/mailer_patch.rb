module RedmineProjectSpecificEmailSender
  module MailerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        def mail(headers={}, &block)
          headers.reverse_merge! 'X-Mailer' => 'Redmine',
                  'X-Redmine-Host' => Setting.host_name,
                  'X-Redmine-Site' => Setting.app_title,
                  'X-Auto-Response-Suppress' => 'All',
                  'Auto-Submitted' => 'auto-generated',
                  'From' => mail_from,
                  'List-Id' => "<#{Setting.mail_from.to_s.gsub('@', '.')}>"

          # Replaces users with their email addresses
          [:to, :cc, :bcc].each do |key|
            if headers[key].present?
              headers[key] = self.class.email_addresses(headers[key])
            end
          end
          # Removes the author from the recipients and cc
          # if the author does not want to receive notifications
          # about what the author do
          if @author && @author.logged? && @author.pref.no_self_notified
            addresses = @author.mails
            headers[:to] -= addresses if headers[:to].is_a?(Array)
            headers[:cc] -= addresses if headers[:cc].is_a?(Array)
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
            if defined? @user
              headers[:message_id] = "<#{self.class.message_id_for(@message_id_object, @user)}>"
            else
              headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
            end
          end
          if @references_objects
            if defined? @user
              headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o, @user)}>"}.join(' ')
            else
              headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
            end
          end

          m = if block_given?
            super headers, &block
          else
            super headers do |format|
              format.text
              format.html unless Setting.plain_text_mail?
            end
          end
          set_language_if_valid @initial_language
          m
        end

        # alias_method_chain :mail_from, :project_specific_email
        alias_method :mail_from_without_project_specific_email, :mail_from
        alias_method :mail_from, :mail_from_with_project_specific_email

        # alias_method_chain :issue_add, :project_specific_email
        alias_method :issue_add_without_project_specific_email, :issue_add
        alias_method :issue_add, :issue_add_with_project_specific_email

        # alias_method_chain :issue_edit, :project_specific_email
        alias_method :issue_edit_without_project_specific_email, :issue_edit
        alias_method :issue_edit, :issue_edit_with_project_specific_email

        # alias_method_chain :document_added, :project_specific_email
        alias_method :document_added_without_project_specific_email, :document_added
        alias_method :document_added, :document_added_with_project_specific_email

        # alias_method_chain :attachments_added, :project_specific_email
        alias_method :attachments_added_without_project_specific_email, :attachments_added
        alias_method :attachments_added, :attachments_added_with_project_specific_email

        # alias_method_chain :news_added, :project_specific_email
        alias_method :news_added_without_project_specific_email, :news_added
        alias_method :news_added, :news_added_with_project_specific_email

        # alias_method_chain :message_posted, :project_specific_email
        alias_method :message_posted_without_project_specific_email, :message_posted
        alias_method :message_posted, :message_posted_with_project_specific_email
      end
    end

    module InstanceMethods
      def mail_from
        Setting.mail_from
      end

      def mail_from_with_project_specific_email
        @project ? @project.email : mail_from_without_project_specific_email
      end

      def issue_add_with_project_specific_email(*args)
        @issue = args.find{|arg| arg.is_a? Issue}
        @project = @issue.project
        issue_add_without_project_specific_email(*args)
      end

      def issue_edit_with_project_specific_email(*args)
        @journal = args.find{|arg| arg.is_a? Journal}
        @project = @journal.journalized.project
        issue_edit_without_project_specific_email(*args)
      end

      def document_added_with_project_specific_email(*args)
        @document = args.find{|arg| arg.is_a? Document}
        @project = @document.project
        document_added_without_project_specific_email(*args)
      end

      def attachments_added_with_project_specific_email(*args)
        @attachments = args.find{|arg| arg.is_a? News}
        @project = @attachments.first.container.project
        attachments_added_without_project_specific_email(*args)
      end

      def news_added_with_project_specific_email(*args)
        @news = args.find{|arg| arg.is_a? News}
        @project = @news.project
        news_added_without_project_specific_email(*args)
      end

      def message_posted_with_project_specific_email(*args)
        @message = args.find{|arg| arg.is_a? Message}
        @project = @message.board.project
        message_posted_without_project_specific_email(*args)
      end
    end
  end
end
