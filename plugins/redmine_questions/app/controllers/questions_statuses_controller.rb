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

class QuestionsStatusesController < ApplicationController
  unloadable
  layout 'admin'

  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index

  accept_api_auth :index

  def index
    respond_to do |format|
      format.api {
        @questions_statuses = QuestionsStatus.sorted
      }
    end
  end

  def new
    @questions_status = QuestionsStatus.new
  end

  def create
    @questions_status = QuestionsStatus.new
    @questions_status.safe_attributes = params[:questions_status]
    if request.post? && @questions_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'plugin', id: 'redmine_questions', controller: 'settings', tab: 'questions_statuses'
    else
      render action: 'new'
    end
  end

  def edit
    @questions_status = QuestionsStatus.find(params[:id])
  end

  def update
    @questions_status = QuestionsStatus.find(params[:id])
    @questions_status.safe_attributes = params[:questions_status]
    if @questions_status.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to action: 'plugin', id: 'redmine_questions', controller: 'settings', tab: 'questions_statuses'
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.js { head 422 }
      end
    end
  end

  def destroy
    QuestionsStatus.find(params[:id]).destroy
    redirect_to action: 'plugin', id: 'redmine_questions', controller: 'settings', tab: 'questions_statuses'
  rescue
    flash[:error] = l(:error_products_unable_delete_questions_status)
    redirect_to action: 'plugin', id: 'redmine_questions', controller: 'settings', tab: 'questions_statuses'
  end
end
