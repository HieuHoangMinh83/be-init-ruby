class V1::ProjectsController < ApplicationController
  def index
    projects = Project.all
    render_success(data: projects, message: "Projects retrieved successfully")
  end

  def show
    project = Project.find(params[:id])
    render_success(data: project, message: "Project retrieved successfully")
  end

  def create
    project_dto = ProjectDto.new(project_params)
    unless project_dto.valid?
      return render_error(errors: project_dto.errors.full_messages, status: :unprocessable_entity)
    end
    project = Project.new(
      name: project_dto.name,
      description: project_dto.description,
      owner_id: current_user.id,
    )
    project.save!
    render_success(data: project, message: "Project created successfully", status: :created)
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
