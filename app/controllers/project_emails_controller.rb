class ProjectEmailsController < ApplicationController
  unloadable

  before_action :load_project, :authorize

  def update
    url = project_settings_tab_url

    @project.email = params[:email]
    if @project.project_email.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @project.project_email.errors.full_messages.join("<br/>")
      url[:email] = params[:email]
    end
    redirect_to url
  end

  def destroy
    @project.project_email.destroy if @project.project_email
    @project.reload

    redirect_to project_settings_tab_url, :notice => l(:notice_email_reset)
  end

  private

  def load_project
    @project = Project.find(params[:project_id])
  end

  def project_settings_tab_url
    { :controller => 'projects', :action => 'settings',
      :id => @project, :tab => 'outbound_email' }
  end
end
