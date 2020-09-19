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

class QuestionsController < ApplicationController
  unloadable

  before_action :find_question, :only => [:edit, :show, :update, :destroy]
  before_action :find_optional_project, :only => [:index, :update_form, :new, :create, :autocomplete_for_subject]
  before_action :find_section, :only => [:new, :create, :update, :edit]
  before_action :find_questions, :only => [:autocomplete_for_subject, :index] #:autocomplete_for_subject

  helper :questions
  helper :watchers
  helper :attachments

  include QuestionsHelper

  def index
    @question_item = Question.new
  end

  def new
    @question_item = Question.new
    @question_item.section ||= @section
  end

  def show
    @answers = @question_item.answers.by_accepted.by_votes.by_date
    if @answers
      @limit = Setting.issues_export_limit.to_i
      @answer_count = @answers.count
      @answer_pages = Paginator.new @answer_count, @limit, (params[:page] || 1)
      @offset ||= @answer_pages.offset
    end
    @answer = QuestionsAnswer.new
    @answer.question = @question_item
    @question_item.view request.remote_addr, User.current
  end

  def update
    (render_403; return false) unless @question_item.editable_by?(User.current)
    @question_item.safe_attributes = params[:question]
    @question_item.save_attachments(params[:attachments])
    if @question_item.save
      flash[:notice] = l(:label_question_successful_update)
      respond_to do |format|
        format.html {redirect_to :action => :show, :id => @question_item}
      end
    else
      respond_to do |format|
        format.html { render :edit}
      end
    end
  end

  def update_form
    @question_item = Question.new
    @question_item.safe_attributes = params[:question]
  end

  def create
    @question_item = Question.new
    @question_item.section = @section
    @question_item.safe_attributes = params[:question]
    @question_item.author = User.current
    @question_item.save_attachments(params[:attachments])

    respond_to do |format|
      if @question_item.save
        format.html { redirect_to :action => :show, :id => @question_item}
      else
        format.html { render :action => 'new' }
      end
    end
  end

  def autocomplete_for_subject
    render :layout => false
  end

  # def convert_issue_to_question
  #   issue = Issue.visible.find(params[:issue_id])
  #   question = Question.from_issue(issue)
  #   if question.save
  #     issue.destroy if params[:destroy]
  #     redirect_to _question_path(question)
  #   else
  #     redirect_back_or_default({:controller => 'issues', :action => 'show', :id => issue})
  #   end
  # end

  # def convert_to_issue
  #   issue = @question_item.to_issue
  #   if issue.save
  #     redirect_to issue_path(issue)
  #   else
  #     redirect_back_or_default question_path(@question_item)
  #   end
  # end

  def destroy
    back_id = @question_item.section
    if @question_item.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_back_or_default questions_path(:section_id => back_id) }
      format.api  { render_api_ok }
    end
  end

  def preview
    if params[:id].present? && query = Question.find_by_id(params[:question_id])
      @previewed = query
    end
    @text = (params[:question] ? params[:question][:content] : nil)
    render :partial => 'common/preview'
  end

  private

  def find_questions
    seach = params[:q] || params[:topic_search]
    @section = QuestionsSection.find(params[:section_id]) if params[:section_id]

    scope = Question.visible
    scope = scope.where(:section_id => @section) if @section

    columns = ['subject', 'content']
    tokens = seach.to_s.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') }.uniq.select { |w| w.length > 1 }
    tokens = [] << tokens unless tokens.is_a?(Array)
    token_clauses = columns.collect { |column| "(LOWER(#{column}) LIKE ?)" }
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(' AND ')
    find_options = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]

    scope = scope.in_project(@project)
    scope = scope.where(find_options) unless tokens.blank?
    @sort_order = params[:sort_order]
    case @sort_order
    when 'popular'
      scope = scope.by_views.by_update
    when 'newest'
      scope = scope.by_date
    when 'active'
      scope = scope.by_update
    when 'unanswered'
      scope = scope.questions.where(:answers_count => 0)
    else
      scope = scope.by_votes.by_views.by_update
    end

    @limit =  per_page_option
    @offset = params[:page].to_i * @limit
    scope = scope.limit(@limit).offset(@offset)
    scope = scope.tagged_with(params[:tag]) if params[:tag].present?

    @topic_count = scope.count
    @topic_pages = Paginator.new @topic_count, @limit, params[:page]

    @question_items = scope
  end

  def find_section
    @section = QuestionsSection.find_by_id(params[:section_id] || (params[:question] && params[:question][:section_id]))
    @section ||= @project.questions_sections.first if @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_question
    if Redmine::VERSION.to_s =~ /^2.6/
      @question_item = Question.visible.find(params[:id], readonly: false)
    else
      @question_item = Question.visible.find(params[:id])
    end
    return deny_access unless @question_item.visible?
    @project = @question_item.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
