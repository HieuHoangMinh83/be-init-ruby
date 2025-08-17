module ProjectsHandle
  extend ActiveSupport::Concern
  include ResponseHandle
  class << self
    def create_project_and_return(project_params, current_user)
      project_dto = ProjectCreateDto.new(project_params)
      unless project_dto.valid?
        return ResponseHandle.render_error(self, message: project_dto.errors.full_messages.join(", "), status: :unprocessable_entity)
      end
      project = Project.new(
        name: project_dto.name,
        description: project_dto.description,
        owner_id: current_user.id,
      )
      if project.save
        ResponseHandle.render_success(self, data: project, message: "Project created successfully", status: :created)
      else
        ResponseHandle.render_error(self, message: "Failed to create project", status: :unprocessable_entity)
      end
    end

    def update_project_and_return(project_params, project)
      project_dto = ProjectUpdateDto.new(project_params)
      unless project_dto.valid?
        return ResponseHandle.render_error(self, message: project_dto.errors.full_messages.join(", "), status: :unprocessable_entity)
      end

      if project.update(name: project_dto.name, description: project_dto.description)
        ResponseHandle.render_success(self, data: project, message: "Project updated successfully", status: :update)
      else
        ResponseHandle.render_error(self, message: "Failed to update project", status: :unprocessable_entity)
      end
    end

    def destroy_project_and_return(project)
      if project.destroy
        ResponseHandle.render_success(self, message: "Project deleted successfully", status: :ok)
      else
        ResponseHandle.render_error(self, message: "Failed to delete project", status: :unprocessable_entity)
      end
    end
  end
end
