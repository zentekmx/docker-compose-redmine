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

class QuestionsAnswer < ActiveRecord::Base
  unloadable

  include Redmine::SafeAttributes
  extend ApplicationHelper

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :question, :counter_cache => 'answers_count', :touch => true

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4

  acts_as_attachable_questions

  acts_as_event :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'questions', :action => 'show', :id => o.question, :anchor => "questions_answer_#{o.id}" }},
                :group => :question,
                :type => Proc.new {|o| 'icon icon-reply'},
                :description => :content,
                :title => Proc.new {|o| o.question.subject }

  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider :type => 'questions',
                              :permission => :view_questions,
                              :author_key => :author_id,
                              :timestamp => "#{table_name}.created_on",
                              :scope => joins({ :question => { :section => :project } }, :author)
  else
    acts_as_activity_provider :type => 'questions',
                              :permission => :view_questions,
                              :author_key => :author_id,
                              :timestamp => "#{table_name}.created_on",
                              :find_options => { :joins => [{ :question => { :section => :project } }, :author] }
  end

  scope :visible, lambda {|*args| where(Question.visible_condition(args.shift || User.current)) }
  scope :by_votes, lambda { order("#{table_name}.cached_weighted_score DESC") }
  scope :by_accepted, lambda { order("#{table_name}.accepted DESC") }
  scope :by_date, lambda { order("#{table_name}.created_on DESC") }
  scope :featured, lambda {|*args| where(:featured => true) }

  validates_presence_of :question, :author, :content
  validate :cannot_answer_to_locked_question, :on => :create

  after_create :add_author_as_watcher
  after_create :send_notification

  safe_attributes 'author',
                  'content'

  def commentable?(user = User.current)
    return false if question.locked?
    user.allowed_to?(:comment_question, project)
  end

  def cannot_answer_to_locked_question
    # Can not reply to a locked topic
    errors.add :base, 'Question is locked' if question && question.locked?
  end

  def section_name
    question.try(:section).try(:name)
  end

  def project
    question.project if question
  end

  def allow_voting?
    question && question.section && question.section.allow_voting?
  end

  def last_comment
    Comment.where(:commented_type => self.class.name, :commented_id => [id] + answer_ids).order('created_on DESC').last
  end

  def replies_count
    answers.count
  end

  def editable_by?(user)
    (author == user && user.allowed_to?(:edit_own_answers, project)) ||
    user.allowed_to?(:edit_questions, project)
  end

  def destroyable_by?(user)
    user.allowed_to?(:delete_answers, project)
  end

  def votable_by?(user)
    user.allowed_to?(:vote_questions, project)
  end

  private
  def check_accepted
    question.answers.update_all(:accepted => false) if question &&
                                                       accepted? &&
                                                       accepted_changed?
  end
  # </PRO>

  def add_author_as_watcher
    Watcher.create(:watchable => question, :user => author)
  end

  def send_notification
    Mailer.question_answer_added(User.current, self).deliver if Setting.notified_events.include?('question_answer_added')
  end
end
