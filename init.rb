require 'redmine'

Redmine::Plugin.register :redmine_project_specific_email_sender do
  name 'Redmine Project Specific Email Sender plugin'
  author 'Adam Walters'
  description "This is a plugin for Redmine which allows each project to have it's own sender email address for project related, outbound emails"
  version '1.0.3'
  requires_redmine :version_or_higher => '5.0'
  permission :edit_project_email, :project_emails => [:update, :destroy]
end

Project.send(:include, RedmineProjectSpecificEmailSender::ProjectPatch)
Mailer.send(:include, RedmineProjectSpecificEmailSender::MailerPatch)
ProjectsHelper.send(:include, RedmineProjectSpecificEmailSender::ProjectsHelperPatch)

