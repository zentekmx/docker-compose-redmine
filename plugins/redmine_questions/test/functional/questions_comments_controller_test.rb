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

class QuestionsCommentsControllerTest < ActionController::TestCase
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
    @controller = QuestionsCommentsController.new
    @project = projects(:projects_001)
    @comment = Comment.new(:comments => "Text", :author => users(:users_001))
    questions(:question_001).comments << @comment
    User.current = nil
  end

  def test_create_comment_for_question
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    user = User.find(2)
    user.pref.no_self_notified = false
    user.pref.save
    Watcher.create(:watchable => questions(:question_001), :user => user)
    comment_text = 'text for comment #123'

    with_settings :notified_events => %w[question_comment_added] do
      assert_difference 'Comment.count', 1 do
        compatible_request :post, :create, :source_type => 'question', :source_id => 1, :comment => { :comments => comment_text }
      end
    end

    question = questions(:question_001)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail, 'Notification has to be sent'
    assert_equal "[#{question.project.identifier} - #{question.section.name} - q&a#{question.id}] RE: Hard question", mail.subject
    assert_mail_body_match comment_text, mail

    assert_response :redirect
    question_comments = question.comments.order(:created_on).map{|c| c.try(:comments) || c.try(:content)}
    assert_match comment_text, question_comments.join(', ')
  end

  def test_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :source_type => 'question', :source_id => questions(:question_001), :id => @comment
    assert_response :success
  end

  def test_update
    @request.session[:user_id] = 1
    compatible_request :post, :update, :source_type => 'question', :source_id => questions(:question_001), :id => @comment,
                  :comment => {
                    :comments => 'Update text'
                  }
    @comment.reload
    assert_response :redirect
    assert_equal 'Update text', @comment.comments
  end

  def test_destroy
    @request.session[:user_id] = 1
    assert_difference 'Comment.count', -1 do
      compatible_request :delete, :destroy, :source_type => 'question', :source_id => questions(:question_001), :id => @comment
    end
  end
end
