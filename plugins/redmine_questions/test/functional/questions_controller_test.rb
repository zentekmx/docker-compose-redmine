# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class QuestionsControllerTest < ActionController::TestCase
  fixtures :users,
           :projects,
           :roles,
           :members,
           :member_roles,
           :trackers,
           :enumerations,
           :projects_trackers,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :attachments,
           :workflows,
           :time_entries,
           :questions,
           :questions_answers,
           :questions_sections

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:tags, :taggings, :comments])

  def setup
    RedmineQuestions::TestCase.prepare
    @controller = QuestionsController.new
    @project    = projects(:projects_001)
    @dev_role   = Role.find(2)
    @dev_role_permissions = @dev_role.permissions
    User.current = nil
  end

  def test_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index, :project_id => @project
    assert_response :success
    assert_select 'div.topic h3.subject', {:count => @project.questions.count}
    assert_select 'div.contextual a.icon-add', {:href => new_project_question_url(@project)}
    latest_subject = Question.by_date.in_project(@project).limit(5)
    assert_select 'ul.related-topics li', {:count => latest_subject.count}
  end

  def test_get_index_with_section
    @request.session[:user_id] = 1
    section = questions_sections(:section_001)
    compatible_request :get, :index, :section_id => section.id, :project_id => section.project.id
    assert_response :success
    assert_select 'h2', {:text => section.name}
    assert_select 'p.breadcrumb'
  end

  def test_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new, project_id: @project

    assert_select 'input#question_subject'
    assert_select 'select#question_section_id'
    assert_select 'input[type=?]', 'submit'
  end

  def test_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, id: 1

    assert_select 'input#question_subject'
    assert_select 'select#question_section_id'
    assert_select 'input[type=?]', 'submit'
  end

  def test_post_create_failed
    @request.session[:user_id] = 1
    compatible_request :post, :create, :project_id => @project,
      :question => {

        :content => "Body of text"
    }
    assert_response :success
  end

  def test_post_create
    @request.session[:user_id] = 1
    ActionMailer::Base.deliveries.clear
    user = User.find(1)
    user.pref.no_self_notified = false
    user.pref.save

    with_settings :notified_events => %w(question_added) do
      assert_difference 'Question.count' do
        compatible_request :post, :create, :project_id => @project, :question => { :subject => 'Topic for new question',
                                                              :content => 'Body of text',
                                                              :section_id => 1 }
      end
    end
    question = Question.where(:subject => 'Topic for new question').first
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal "[#{question.project.identifier} - #{question.section.name} - q&a#{question.id}] Topic for new question", mail.subject
    assert_mail_body_match 'Body of text', mail
  end

  def test_post_create_failed
    @request.session[:user_id] = 1
    compatible_request :post, :create, :project_id => @project,
      :question => {

        :content => "Body of text"
    }
    assert_response :success
  end

  def test_get_show
    @request.session[:user_id] = 1
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'div h1', {:text => questions(:question_001).subject}
    assert_match questions(:question_001).content, @response.body
    assert_select 'div.add_comments .add-comment-form textarea'
    assert_select 'div#reply'
    assert_select 'a.icon-del'
    assert_select 'a.add-comment-link'
    assert_select 'span.items', {:text => "(1-2/2)"}
    @dev_role.permissions << :add_answers
    @dev_role.save
    @request.session[:user_id] = 3
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'div h1', :text => questions(:question_001).subject
    assert_match questions(:question_001).content, @response.body
    assert_select 'div.add_comments .add-comment-form textarea', :count => 0
    assert_select 'div#reply'
    assert_select 'a.icon-del', :count => 0

    @dev_role.permissions << :delete_questions
    @dev_role.save
    @request.session[:user_id] = 3
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'div h1', :text => questions(:question_001).subject
    assert_match questions(:question_001).content, @response.body
    assert_select 'div.add_comments .add-comment-form textarea', :count => 0
    assert_select 'div#reply'
    assert_select 'a.icon-del'

    @dev_role.permissions << :comment_question
    @dev_role.save
    @request.session[:user_id] = 3
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'div h1', :text => questions(:question_001).subject
    assert_match questions(:question_001).content, @response.body
    assert_select 'div.add_comments .add-comment-form textarea', :count => 1
    assert_select 'div#reply'
    assert_select 'a.icon-del'

    @dev_role.permissions = @dev_role_permissions
    @dev_role.save
  end

  def test_destroy
    @request.session[:user_id] = 1
    question = questions(:question_001)
    assert_difference 'Question.count', -1 do
      compatible_request :post, :destroy, :id => question.id
    end
    assert_redirected_to questions_path(:section_id => question.section)
    assert_nil Question.find_by_id(question.id)
  end

  def test_preview_new_question
    @request.session[:user_id] = 1
    question = questions(:question_001)
    compatible_xhr_request :post, :preview,
      :question => {
        :content => "Previewed question",
      }
    assert_response :success
    assert_select 'p', :text => 'Previewed question'
  end

  def test_update_question
    @request.session[:user_id] = 1
    question = Question.find 1
    compatible_request :put, :update, :id => question.id,
      :question => {
        :content => "Update question",
        :subject => "Changed subject",
        :section_id => 1
      }
    question.reload
    assert_equal "Update question", question.content
    assert_equal "Changed subject", question.subject
  end

  def test_search_question
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :autocomplete_for_subject, :project_id => @project, :q => "Hard"
    assert_response :success
    assert_select 'h3.subject', {:count => 2}
  end

  def test_should_not_get_create_by_deny_user
    @request.session[:user_id] = 4
    compatible_request :post, :create, :project_id => @project,
      :question => {
        :subject => "Topic for new question",
        :content => "Body of text"
      }
    assert_response :forbidden
  end

  def test_should_not_allowed_to_update_question_by_deny_user
    @request.session[:user_id] = 4
    compatible_request :post, :update, :project_id => @project, :id => 1,
      :question => {
        :content => "new text",
        :subject => "Changed subject"
      }
    assert_not_equal Question.find(1).subject, 'Changed subject'
  end

  # def test_convert_issue_to_question
  #   @request.session[:user_id] = 1
  #   compatible_request :get, :convert_issue_to_question, :project_id => @project, :issue_id => 1
  #   assert_response :redirect
  #   assert_equal Question.last.subject, Issue.find(1).subject
  # end

  # def test_convert_to_issue
  #   @request.session[:user_id] = 2
  #   compatible_request :get, :convert_to_issue, :project_id => @project, :id => 1
  #   issue = Issue.where(:subject => questions(:question_001).subject).first
  #   assert issue, "Not found issue after convertion"
  # end

end
