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

class QuestionsStatusesControllerTest < ActionController::TestCase
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

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:questions,
                                                                                                                      :questions_answers,
                                                                                                                      :questions_sections,
                                                                                                                      :questions_statuses])

  def setup
    RedmineQuestions::TestCase.prepare
    @project = Project.find(1)
    User.current = nil
  end

  def test_new
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success

    assert_select 'input#questions_status_name'
    assert_select 'input[type=?]', 'submit'
  end

  def test_create
    @request.session[:user_id] = 1
    assert_difference 'QuestionsStatus.count' do
      compatible_request :post, :create, questions_status: { name: 'Test status', color: 'green', is_closed: '0' }
    end
    assert_equal 'Test status', QuestionsStatus.last.name
  end

  def test_delete
    @request.session[:user_id] = 1

    status = QuestionsStatus.find(1)
    assert_difference 'QuestionsStatus.count', -1 do
      compatible_request :delete, :destroy, id: status
    end
    assert_nil QuestionsStatus.where(id: status.id).first
  end

  def test_update
    @request.session[:user_id] = 1

    status = QuestionsStatus.find(1)
    compatible_request :put, :update, id: status, questions_status: { name: 'New name', color: 'green', is_closed: '0' }
    status.reload
    assert_equal status.name, 'New name'
  end
end
