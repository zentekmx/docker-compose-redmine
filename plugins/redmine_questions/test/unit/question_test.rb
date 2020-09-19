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

class QuestionTest < ActiveSupport::TestCase
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

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', 
      [:comments, :tags, :taggings])

  def setup
    RedmineQuestions::TestCase.prepare
  end

  def question(x)
    q = 'question_'
    q += '0' * (3 - x.to_s.length) + x.to_s
    questions(q.to_sym)
  end

  def answer(x)
    q = 'answer_'
    q += '0' * (3 - x.to_s.length) + x.to_s
    questions_answers(q.to_sym)
  end

  def test_creating
    new_question = Question.new
    new_question.subject = 'Some new question'
    new_question.author = users(:users_001)
    new_question.section = questions_sections(:section_001)
    assert !new_question.save, 'Content cannot be blank'
  end

  def test_require_author
    new_question = Question.new(:subject => 'Some new question')
    assert !new_question.save, 'Question must have author'
  end

  def test_require_topic
    new_question = Question.new(:author => users(:users_001))
    assert !new_question.save, 'Question must have topic'
  end

  def test_creating_answer
    answer = QuestionsAnswer.new
    answer.author = users(:users_002)
    answer.content = 'Answer text'
    answer.question = question(1)
    assert answer.save, 'Failed to save the answer'
  end

  def test_save_answer_without_question_relation
    answer = answer(1)
    answer.question = nil
    assert !answer.save, 'Can save answer without question'
  end

  def test_add_answer_for_question
    question = question(3)
    new_ans = QuestionsAnswer.new
    new_ans.author = users(:users_001)
    new_ans.question = question
    new_ans.content = 'some text'
    assert new_ans.save
    assert_equal question.answers.count, 1
  end

  def test_diny_add_answer_for_locked_question
    question = question(4)
    new_ans = QuestionsAnswer.new
    new_ans.author = users(:users_001)
    new_ans.question = question
    new_ans.content = 'some text'
    assert !new_ans.valid?
  end

  def test_destroy_question_with_answer
    question = question(1)
    ans = question.answers.first
    question.destroy
    assert_raises(ActiveRecord::RecordNotFound) { QuestionsAnswer.find(ans.id) }
  end

  def test_questions_for_project
    assert_equal Question.in_project(projects(:projects_001)).count, 2
  end

  def test_related_questions
    related_questons = Question.related(question(1), 2)
    assert_equal 1, related_questons.size
    related_questons.each do |rq|
      assert_match /question/, rq.subject
    end
  end

  def test_add_comment
    question = Question.find 1
    comment = Comment.new(:comments => 'comment text', :author => users(:users_001))
    assert question.comments << comment, 'Error with adding comment to question'
    question.comments.reload
    assert_equal question.comments.size, 2
  end

  def test_commetable
    assert question(1).commentable?(users(:users_002)), "Question not commentable for user with permission"
    assert !question(1).commentable?(users(:users_004)), "Question commentable for user without permission"
  end

  def test_editable_by
    assert question(1).editable_by?(users(:users_002)), "Question not editable for user with permission"
    assert !question(1).editable_by?(users(:users_004)), "Question editable for user without permission"
  end

  def test_votable_by
    assert question(1).votable_by?(users(:users_002)), "User with permission can not vote by question"
    assert !question(1).votable_by?(users(:users_004)), "User #4 can vote by question"
  end

  def test_accepted_answer
    answer = answer(1)
    question = question(1)
    answer.accepted = true
    assert answer.accepted?, 'Mark as accepted_answer did not set for answer'
    assert question.answered?, 'Mark as accepted_answer did set for question'
  end
end
