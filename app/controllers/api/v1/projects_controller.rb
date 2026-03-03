class Api::V1::ProjectsController < ApplicationController
  respond_to :json

  before_action :set_project, only: %i[update destroy]

  def index
    @projects = current_user.projects
    render json: @projects, status: :ok
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      render json: @project, status: :created
    else
      render json: { errors: @project.errors.to_hash }, status: :unprocessable_content
    end
  end

  def update
    if @project.update(project_params)
      render json: @project, status: :ok
    else
      render json: { errors: @project.errors.to_hash }, status: :unprocessable_content
    end
  end

  def destroy
    @project = current_user.projects.find(params[:id])
    @project.destroy
    head :no_content
  end

  private

  def project_params
    params.require(:project).permit(:name, :description, :color, :archived)
  end

  def set_project
    @project = current_user.projects.find(params[:id])
  end
end
