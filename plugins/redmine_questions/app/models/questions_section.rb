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

class QuestionsSection < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :questions, :foreign_key => "section_id", :dependent => :destroy

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'project', 'position', 'description', 'section_type'

  scope :with_questions_count, lambda {
    select("#{QuestionsSection.table_name}.*, count(#{QuestionsSection.table_name}.id) as questions_count").
    joins(:questions).
    order("project_id ASC").
    group(QuestionsSection.column_names.map { |column| "#{QuestionsSection.table_name}.#{column}" }.join(', '))
  }
  scope :for_project, lambda { |project| where(:project_id => project) unless project.blank? }
  scope :visible, lambda {|*args|
    joins(:project).
    where(Project.allowed_to_condition(args.shift || User.current, :view_questions, *args))
  }
  scope :sorted, lambda { order(:position) }

  rcrm_acts_as_list :scope => 'project_id = #{project_id}'
  acts_as_watchable

  SECTION_TYPE_QUESTIONS = 'questions'

  validates_presence_of :section_type, :project_id, :name
  validates_uniqueness_of :name, :scope => :project_id

  def initialize(attributes=nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.section_type ||= SECTION_TYPE_QUESTIONS
    end
  end

  def to_param
    "#{id}-#{ActiveSupport::Inflector.transliterate(name).parameterize}"
  end

  def is_questions?
    true
  end

  def is_solutions?
    false
  end

  def is_ideas?
    false
  end

  def allow_voting?
    false
  end

  def allow_liking?
    false
  end

  def allow_answering?
    is_questions?
  end

  def self.types_list
  end

  def l_type
    I18n.t("label_questions_section_type_#{section_type}") if section_type
  end

  def to_s
    name
  end
end
