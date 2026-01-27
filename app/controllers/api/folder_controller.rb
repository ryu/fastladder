class Api::FolderController < ApplicationController
  before_action :login_required_api
  # we need not check folder_id, because it checked by each method
  params_required :name, only: %i[create update]
  skip_before_action :verify_authenticity_token

  ERR_ALREADY_EXISTS = 10

  def create
    name = params[:name]
    folder = nil

    Folder.transaction do
      if @member.folders.find_by(name: name)
        return head :unprocessable_content if turbo_stream_request?

        return render_json_status(false, ERR_ALREADY_EXISTS)
      end

      folder = @member.folders.create(name: name)
    end

    if turbo_stream_request?
      render turbo_stream: turbo_stream.append("manage_folder", partial: "api/folder/folder", locals: { folder: folder })
    else
      render_json_status(true)
    end
  end

  def delete
    unless (folder = get_folder)
      return head :not_found if turbo_stream_request?

      return render_json_status(false)
    end

    folder_id = folder.id
    folder.destroy

    if turbo_stream_request?
      render turbo_stream: turbo_stream.remove("folder-#{folder_id}")
    else
      render_json_status(true)
    end
  end

  def update
    unless (folder = get_folder)
      return head :not_found if turbo_stream_request?

      return render_json_status(false)
    end

    name = params[:name]
    folder.update(name: name)

    if turbo_stream_request?
      render turbo_stream: turbo_stream.replace("folder-#{folder.id}", partial: "api/folder/folder", locals: { folder: folder })
    else
      render_json_status(true)
    end
  end

  protected

  def get_folder
    if (folder_id = params[:folder_id].to_i).positive?
      return @member.folders.find_by(id: folder_id)
    end

    nil
  end
end
