# This file is a part of Redmine Q&A (redmine_questions) plugin,
# Q&A plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_questions is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_questions is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_questions.  If not, see <http://www.gnu.org/licenses/>.

class QuestionsSectionsController < ApplicationController
  menu_item :questions

  before_action :find_section, :only => [:edit, :update, :destroy]
  before_action :find_optional_project, :only => [:index, :new, :create]

  helper :questions

  def new
    @section = @project.questions_sections.build

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @section = @project.nil? ? QuestionsSection.new : @project.questions_sections.build
    @section.safe_attributes = params[:questions_section]
    if @section.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to_settings_in_projects
        end
        format.js
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js
      end
    end
  end

  def edit
  end

  def update
    @section.safe_attributes = params[:questions_section]
    @section.insert_at(@section.position) if @section.position_changed?
    if @section.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_in_projects
        end
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js { head 422 }
      end
    end
  end

  def destroy
    @section.destroy
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
    end
  end

  def index
    ApplicationController.menu_item :questions
    @question_item = Question.new
    @sections = QuestionsSection.visible.order(:project_id).sorted.for_project(@project)
    redirect_to project_questions_path(:section_id => @sections.last, :project_id => @sections.last.project) if @sections.size == 1

    @sections = @sections.with_questions_count
  end

private

  def find_section
    @section = QuestionsSection.find(params[:id])
    @project = @section.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_settings_in_projects
    redirect_back_or_default( @project ? settings_project_path(@project, :tab => 'questions') : plugin_settings_path(:id => "redmine_questions"))
  end

end
