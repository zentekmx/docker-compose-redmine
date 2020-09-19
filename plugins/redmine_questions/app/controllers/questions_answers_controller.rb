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

class QuestionsAnswersController < ApplicationController
  unloadable

  before_action :find_question, :only => [:new, :create]
  before_action :find_answer, :only => [:update, :destroy, :edit, :show]

  helper :questions
  helper :watchers
  helper :attachments

  include QuestionsHelper

  def new
    @answer = QuestionsAnswer.new(:question => @question_item)
  end

  def edit
    (render_403; return false) unless @answer.editable_by?(User.current)
  end

  def update
    (render_403; return false) unless @answer.editable_by?(User.current) || User.current.allowed_to?(:accept_answers, @project)
    @answer.safe_attributes = params[:answer]
    @answer.save_attachments(params[:attachments])
    if @answer.save
      flash[:notice] = l(:label_answer_successful_update)
      respond_to do |format|
        format.html { redirect_to_question }
      end
    else
      respond_to do |format|
        format.html { render :edit}
      end
    end
  end

  def create
    @answer = QuestionsAnswer.new
    @answer.author = User.current
    @answer.question = @question_item
    @answer.safe_attributes = params[:answer]
    @answer.save_attachments(params[:attachments])
    if @answer.save
      flash[:notice] = l(:label_answer_successful_added)
      render_attachment_warning_if_needed(@answer)
    end
    redirect_to_question
  end

  def destroy
    if @answer.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_to_question }
        format.api { render_api_ok }
      end
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
  end

  def preview
    if params[:id].present? && answer = Question.find_by_id(params[:id])
      @previewed = answer
    end
    @text = (params[:answer] ? params[:answer][:content] : nil)
    render :partial => 'common/preview'
  end

  private

  def redirect_to_question
    redirect_to question_path(@answer.question, :anchor => "questions_answer_#{@answer.id}")
  end

  def find_answer
    @answer = QuestionsAnswer.find(params[:id])
    @question_item = @answer.question
    @project = @question_item.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_question
    @question_item = Question.visible.find(params[:question_id]) unless params[:question_id].blank?
    @project = @question_item.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
