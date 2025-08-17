# app/controllers/concerns/handle_response.rb
module ResponseHandle
  extend ActiveSupport::Concern

  class << self
    def render_success(controller, data: nil, message: "Thành công", status: :ok, serializer: nil)
      if serializer
        data = ActiveModelSerializers::SerializableResource.new(data, serializer: serializer)
      else
        if data.respond_to?(:as_json)
          data = data.as_json(except: [:password, :refresh_token])
        end
      end

      controller.render json: {
        success: true,
        message: message,
        data: data,
        status: status,
      }, status: status
    end

    def render_error(controller, message: "Lỗi xảy ra", status: :bad_request)
      controller.render json: {
        success: false,
        message: message,
        status: status,
      }, status: status
    end
  end
end
