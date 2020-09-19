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

class QuestionsCommentsController < ApplicationController
  before_action :find_comment_source

  helper :questions

  def create
    raise Unauthorized unless @comment_source.commentable?

    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @comment_source.comments << @comment
      @comment_source.touch
      flash[:notice] = l(:label_comment_added) unless request.xhr?
    end

    respond_to do |format|
      format.html { redirect_to_question }
      format.js
    end
  end

  def edit
    @comment = @comment_source.comments.find(params[:id])
  end

  def update
    @comment = @comment_source.comments.find(params[:id])
    @comment.safe_attributes = params[:comment]
    if @comment.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_question
    else
      render :action => 'edit'
    end
  end

  def destroy
    @comment_source.comments.find(params[:id]).destroy
    redirect_to_question
  end

  private

  def find_comment_source
    comment_source_type = params[:source_type]
    comment_source_id = params[:source_id]

    klass = Object.const_get(comment_source_type.camelcase)
    @comment_source = klass.find(comment_source_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_question
    question = @comment_source.is_a?(QuestionsAnswer) ? @comment_source.question : @comment_source
    redirect_to question_path(question, :anchor => @comment.blank? ? "#{@comment_source.class.name.underscore}_#{@comment_source.id}" : "comment_#{@comment.id}")
  end
end
