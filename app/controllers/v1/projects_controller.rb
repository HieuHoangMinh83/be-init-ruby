class V1::ProjectsController < ApplicationController
  def index
    projects = Project.all
    ResponseHandle.render_success(self, data: projects, message: "Projects retrieved successfully")
  end

  def create
    ProjectsHandle.create_project_and_return(project_params, current_user)
  end

  def update
    project = Project.where(id: params[:ids], user_id: current_user.id)
    if project.empty?
      ResponseHandle.render_error(self, message: "Project not found", status: :not_found)
    else
      ProjectsHandle.update_project_and_return(project_params, project)
    end
  end

  def destroy
    project = Project.where(id: params[:ids], user_id: current_user.id)
    if project.empty?
      ResponseHandle.render_error(self, message: "Project not found", status: :not_found)
    else
      ProjectsHandle.destroy_project_and_return(project.first)
    end
  end

  def own_project
    projects = current_user.projects
    ResponseHandle.render_success(self, data: projects, message: "Own projects retrieved successfully")
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
