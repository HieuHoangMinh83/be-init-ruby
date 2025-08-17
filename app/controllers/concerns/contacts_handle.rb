module ContactsHandle
  extend ActiveSupport::Concern

  class << self
    def create_and_render_contact(controller, contact)
      contact.save && ResponseHandle.render_success(controller, data: contact, message: "Contact created successfully", status: :created)
    end

    def render_invalid_response(controller)
      ResponseHandle.render_error(controller, message: "Invalid contact data", status: :unprocessable_entity)
    end
  end
end
