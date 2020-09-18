require 'redmine'

Redmine::Plugin.register :redmine_project_specific_email_sender do
  name 'Redmine Project Specific Email Sender plugin'
  author 'Adam Walters'
  description "This is a plugin for Redmine which allows each project to have it's own sender email address for project related, outbound emails"
  version '1.0.2'
  permission :edit_project_email, :project_emails => [:update, :destroy]
end

prepare_block = Proc.new do
  Project.send(:include, RedmineProjectSpecificEmailSender::ProjectPatch)
  Mailer.send(:include, RedmineProjectSpecificEmailSender::MailerPatch)
  ProjectsHelper.send(:include, RedmineProjectSpecificEmailSender::ProjectsHelperPatch)
end

if Rails.env.development?
  ((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare { prepare_block.call }
else
  prepare_block.call
end
