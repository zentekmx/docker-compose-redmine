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

class QuestionsSectionsControllerTest < ActionController::TestCase
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
           :workflows,
           :questions,
           :questions_answers,
           :questions_sections

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:questions, :questions_answers, :questions_sections])

  def setup
    RedmineQuestions::TestCase.prepare
    @controller = QuestionsSectionsController.new
    @dev_role   = Role.find(2)
    @project    = Project.find(1)
    @dev_role_permissions = @dev_role.permissions
    User.current = nil
  end

  def test_global_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response 200
    assert_select 'a.section-tile', :count => QuestionsSection.visible.with_questions_count.to_a.size
    assert_select 'div.project-forums h3', :count => 2

    @request.session[:user_id] = 3
    compatible_request :get, :index
    assert_response 200
    assert_select 'a.section-tile', :count => QuestionsSection.visible.where(:project_id => 1).with_questions_count.to_a.size
    assert_select 'div.project-forums h3', :count => 1
    assert_select 'body', :text => /New question/, :count => 0

    @dev_role.permissions = @dev_role_permissions
    @dev_role.save
  end

  def test_project_index
    @request.session[:user_id] = 1
    compatible_request :get, :index, :project_id => 1
    assert_response 200
    assert_select 'a.section-tile', :count => QuestionsSection.where(:project_id => 1).with_questions_count.to_a.size
    assert_select 'a', /New question/

    @request.session[:user_id] = 3
    compatible_request :get, :index, :project_id => 1
    assert_response 200
    assert_select 'a.section-tile', :count => QuestionsSection.where(:project_id => 1).with_questions_count.to_a.size
    assert_select 'body', :text => /New question/, :count => 0

    @dev_role.permissions << :add_questions
    @dev_role.save
    @request.session[:user_id] = 3
    compatible_request :get, :index, :project_id => 1
    assert_response 200
    assert_select 'a', /New question/

    @dev_role.permissions = @dev_role_permissions
    @dev_role.save
  end
    
  def test_new
    @request.session[:user_id] = 1
    compatible_request :get, :new, :project_id => @project
    assert_response :success
  end

  def test_create_for_project
    @request.session[:user_id] = 1
    assert_difference 'QuestionsSection.count' do
      compatible_request :post, :create, :project_id => @project,
        :questions_section => {
          :name => "New section",
          :section_type => "solution"
        }
    end
    assert_equal @project, QuestionsSection.last.project
  end

  def test_delete
    @request.session[:user_id] = 1
    section = questions_sections(:section_001)
    assert_difference 'QuestionsSection.count', -1 do
      compatible_request :delete, :destroy, :id => section
    end
    assert_nil QuestionsSection.find_by_id(section.id)
  end

  def test_update
    @request.session[:user_id] = 1
    section = questions_sections(:section_001)
    compatible_request :put, :update, :id => section, :questions_section => {:name => 'Edited section'}
    section.reload
    assert_equal section.name, 'Edited section'
  end

  def test_new_from_question_form
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :new, :project_id => '1'
    assert_response :success
    assert_equal 'text/javascript', response.content_type
  end

  def test_create_from_question_form
    @request.session[:user_id] = 1
    assert_difference 'QuestionsSection.count' do
      compatible_xhr_request :post, :create, :project_id => '1', :questions_section => { 'section_type' => 'solution', :name => 'add_section_from_question_form' }
    end
    section = QuestionsSection.find_by_name("add_section_from_question_form")
    assert_not_nil section
    assert_equal 1, section.project_id

    assert_response :success
    assert_equal 'text/javascript', response.content_type
    assert_include 'add_section_from_question_form', response.body
  end

end
