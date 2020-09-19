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

class Question < ActiveRecord::Base
  unloadable

  include Redmine::SafeAttributes
  extend ApplicationHelper

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :section, :class_name => 'QuestionsSection', :foreign_key => 'section_id'
  belongs_to :status, :class_name => 'QuestionsStatus', :foreign_key => 'status_id'

  delegate :section_type, :to => :section, :allow_nil => true

  has_many :answers, :class_name => 'QuestionsAnswer', :dependent => :destroy

  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :comments, lambda { order('created_on') }, :as => :commented, :dependent => :delete_all
  else
    has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  end
  rcrm_acts_as_viewed

  acts_as_attachable_questions
  acts_as_watchable

  acts_as_event :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'questions', :action => 'show', :id => o }},
                :type => Proc.new {|o| 'icon ' + (o.is_solution? ? 'icon-solution': 'icon-question')},
                :description => :content,
                :title => Proc.new {|o| o.subject }


  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider :type => 'questions',
                              :permission => :view_questions,
                              :author_key => :author_id,
                              :timestamp => "#{table_name}.created_on",
                              :scope => joins({:section => :project}, :author)
    acts_as_searchable :columns => ["#{table_name}.subject",
                                    "#{table_name}.content",
                                    "#{QuestionsAnswer.table_name}.content"],
                       :scope => joins({:section => :project}, :answers),
                       :project_key => "#{QuestionsSection.table_name}.project_id"
  else
    acts_as_activity_provider :type => 'questions',
                              :permission => :view_questions,
                              :author_key => :author_id,
                              :timestamp => "#{table_name}.created_on",
                              :find_options => { :include => [{:section => :project}, :author] }
    acts_as_searchable :columns => ["#{table_name}.subject",
                                    "#{table_name}.content",
                                    "#{QuestionsAnswer.table_name}.content"],
                       :include => [{:section => :project}, :answers],
                       :project_key => "#{QuestionsSection.table_name}.project_id"
  end

  scope :solutions, lambda { joins(:section).where(:questions_sections => {:section_type => QuestionsSection::SECTION_TYPE_SOLUTIONS}) }
  scope :questions, lambda { joins(:section).where(:questions_sections => {:section_type => QuestionsSection::SECTION_TYPE_QUESTIONS}) }
  scope :by_votes, lambda { order("#{Question.table_name}.cached_weighted_score DESC") }
  scope :by_date, lambda { order("#{Question.table_name}.created_on DESC") }
  scope :by_update, lambda { order("#{Question.table_name}.updated_on DESC") }
  scope :by_views, lambda { order("#{Question.table_name}.views DESC") }
  scope :positive, lambda { where("#{Question.table_name}.cached_weighted_score > 0") }
  scope :featured, lambda {|*args| where(:featured => true) }
  scope :in_section, lambda { |section|
    where(:section_id => section) if section.present?
  }
  scope :in_project, lambda { |project|
    joins(:section => :project).where("#{QuestionsSection.table_name}.project_id = ?", project) if project.present?
  }
  scope :visible, lambda { |*args|
    joins(:section => :project)
      .where(Project.allowed_to_condition(args.shift || User.current, :view_questions, *args))
  }

  validates_presence_of :author, :content, :subject, :section

  after_create :add_author_as_watcher
  after_create :send_notification

  safe_attributes 'author',
                  'subject',
                  'content',
                  'tag_list',
                  'section_id',
                  'status_id'

  safe_attributes 'status_id',
    :if => lambda {|question, user| question.is_idea?}

  def self.visible_condition(user)
    user.reload if user
    global_questions_allowed = user.allowed_to?(:view_questions, nil)
    projects_allowed_to_view_questions = Project.where(Project.allowed_to_condition(user, :view_questions)).pluck(:id)
    allowed_to_view_condition = global_questions_allowed ? "(#{table_name}.project_id IS NULL)" : '(0=1)'
    allowed_to_view_condition += projects_allowed_to_view_questions.empty? ? ' OR (0=1) ' : " OR (#{table_name}.project_id IN (#{projects_allowed_to_view_questions.join(',')}))"

    user.admin? ? '(1=1)' : allowed_to_view_condition
  end

  def self.related(question, limit)
    tokens = question.subject.strip.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).
      collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '').gsub(%r{('|"|`)}, '')}.select{|m| m.size > 3} || ""

    related_questions = where(tokens.map{ |t| "LOWER(subject) LIKE LOWER('%#{t}%')" }.join(' OR '))
    related_questions = related_questions.in_project(question.project)
    related_questions = related_questions.where("#{Question.table_name}.id != ?", question.id)
    related_questions.limit(limit).to_a.compact
  end

  def commentable?(user = User.current)
    return false if locked?
    user.allowed_to?(:comment_question, project)
  end

  def visible?(user=User.current)
    user.allowed_to?(:view_questions, project)
  end

  def to_param
    "#{id}-#{ActiveSupport::Inflector.transliterate(subject || " ").parameterize}"
  end

  def section_name
    section.try(:name)
  end

  def project
    section.project
  end

  def allow_voting?
    false
  end

  def allow_liking?
    section.allow_liking?
  end

  def allow_answering?
    !locked? && section.allow_answering?
  end

  def last_reply
    answers.order('created_on DESC').last
  end

  def last_comment
    Comment.where(:commented_type => self.class.name, :commented_id => [id] + answer_ids).order('created_on DESC').last
  end

  def replies_count
    answers.count
  end

  def editable_by?(user)
    (author == user && user.allowed_to?(:edit_own_questions, project)) ||
      user.allowed_to?(:edit_questions, project)
  end

  def destroyable_by?(user)
    user.allowed_to?(:delete_questions, project)
  end

  def votable_by?(user)
    user.allowed_to?(:vote_questions, project)
  end

  def convertable_by?(user)
    return false if project.blank?
    user.allowed_to?(:convert_questions, project)
  end

  def answered?
    answers.where(:accepted => true).any?
  end

  def is_question?
    section && section.is_questions?
  end

  def is_solution?
    section && section.is_solutions?
  end

  def is_idea?
    section && section.is_ideas?
  end

  # def to_issue
  #   issue = Issue.new
  #   issue.author = self.author
  #   issue.created_on = self.created_on
  #   issue.subject = self.subject
  #   issue.description = self.content
  #   issue.watchers = self.watchers
  #   issue.attachments = self.attachments
  #   issue.project = self.project
  #   issue.tracker = self.project.trackers.first
  #   issue.status = IssueStatus.first
  #   self.answers.each do |ans|
  #     journal = Journal.new(:notes => ans.content, :user => ans.author)
  #     issue.journals << journal
  #   end
  #   issue
  # end

  # def self.from_issue(issue)
  #   question = Question.new
  #   question.author = issue.author
  #   question.created_on = issue.created_on
  #   question.subject = issue.subject
  #   question.content = issue.description.blank? ? issue.subject : issue.description
  #   question.watchers = issue.watchers
  #   question.attachments = issue.attachments
  #   question.project = issue.project
  #   question.section = issue.project.questions_sections.first
  #   issue.journals.select{|j| j.notes.present?}.each do |journal|
  #     reply = Question.new
  #     reply.author = journal.user
  #     reply.created_on = journal.created_on
  #     reply.content = journal.notes
  #     reply.project = issue.project
  #     reply.question = question
  #     question.answers << reply
  #   end
  #   question
  # end

  def notified_users
    project.notified_users.select { |user| visible?(user) }.collect(&:mail)
  end

  def self.to_text(input)
    textile_glyphs = {
      '&#8217;' => "'",
      '&#8216' => "'",
      '&lt;' => '<',
      '&gt;' => '>',
      '&#8221;' => "'",
      '&#8220;' => '"',
      '&#8230;' => '...',
      '\1&#8212;' => '--',
      ' &rarr; ' => '->',
      '&para;' => ' ',
      ' &#8211; ' => '-',
      '&#215;' => '-',
      '&#8482;' => '(TM)',
      '&#174;' => '(R)',
      '&#169;' => '(C)',
      '&amp;' => '&'
    }.freeze

    html_regexp = /<(?:[^>"']+|"(?:\\.|[^\\"]+)*"|'(?:\\.|[^\\']+)*')*>/xm

    input.dup.gsub(html_regexp, '').tap do |h|
      textile_glyphs.each do |entity, char|
        h.gsub!(entity, char)
      end
    end
  end

  private

  def add_author_as_watcher
    Watcher.create(:watchable => self, :user => author)
  end

  def send_notification
    Mailer.question_question_added(User.current, self).deliver if Setting.notified_events.include?('question_added')
  end
end
