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

class QuestionsAnswersControllerTest < ActionController::TestCase
  fixtures :users, :projects, :roles,
           :members,
           :member_roles,
           :trackers,
           :enumerations,
           :issue_statuses,
           :projects_trackers,
           :questions,
           :questions_answers,
           :questions_sections

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:questions, :questions_answers, :questions_sections])

  def setup
    RedmineQuestions::TestCase.prepare
    @controller = QuestionsAnswersController.new
    @project = projects(:projects_001)
    User.current = nil
  end

  def test_post_create
    @request.session[:user_id] = 1
    ActionMailer::Base.deliveries.clear
    user = User.find(1)
    user.pref.no_self_notified = false
    user.pref.save
    Watcher.create(:watchable => questions(:question_001), :user => user)

    question = questions(:question_001)
    old_answer_count = question.answers.count
    with_settings :notified_events => %w(question_answer_added) do
      assert_difference 'QuestionsAnswer.count' do
        compatible_request(
          :post,
          :create,
          project_id: @project,
          question_id: question,
          answer: {
            content: 'Answer for the first question',
            question_id: question
          }
        )
      end
    end

    answer = QuestionsAnswer.order(:created_on).last

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal "[#{question.project.identifier} - #{question.section.name} - q&a#{question.id}] - answ##{answer.id} - RE: Hard question", mail.subject
    assert_mail_body_match 'Answer for the first question', mail

    assert_redirected_to :controller => 'questions',
                         :action => 'show',
                         :id => question,
                         :anchor => "questions_answer_#{QuestionsAnswer.order(:id).last.id}"
    assert_equal old_answer_count + 1, question.answers.count
    assert_equal 'Answer for the first question', question.answers.last.content
  end

  def test_preview_new_answer
    @request.session[:user_id] = 1
    answer = questions_answers(:answer_002)
    compatible_xhr_request :post, :preview,  
      :answer => {
        :content => "Previewed answer",
      }
    assert_response :success
    assert_select 'p', :text => 'Previewed answer'
  end
  
  def test_preview_edited_answer
    @request.session[:user_id] = 1
    answer = questions_answers(:answer_002)
    compatible_xhr_request :post, :preview, :id => answer.id, 
      :answer => {
        :content => "Previewed answer 1",
      }
    assert_response :success
    assert_select 'p', :text => 'Previewed answer 1'
  end

  def test_destroy
    @request.session[:user_id] = 1
    answer = questions_answers(:answer_002)
    question = answer.question
    assert_difference 'QuestionsAnswer.count', -1 do
      compatible_request :post, :destroy, :id => answer.id
    end
    assert_redirected_to question_path(answer.question, :anchor => "questions_answer_#{answer.id}") 
    assert_nil QuestionsAnswer.find_by_id(answer.id)
  end  

  def test_add_answer_to_locked_question
    @request.session[:user_id] = 1
    question = questions(:question_004)
    assert_no_difference 'QuestionsAnswer.count' do
      compatible_request :post, :create, :project_id => @project, :question_id => question.id,
           :answer => { :content => 'Body of answer', :question_id => question.id }
    end                  
  end

  def test_update_answer_with_mark_as_accepted_without_permission
    @request.session[:user_id] = 3
    answer = questions_answers(:answer_002)
    compatible_request :post, :update, :id => answer.id,
      :answer => {
        :content => "Body of answer (changed)",
        :accepted => 1
      }
    # assert_response :success
    answer.reload
    assert !answer.accepted, "Mark as official answer did set for answer after update for user without permission"
  end
end
