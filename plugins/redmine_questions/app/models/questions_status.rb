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

class QuestionsStatus < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  belongs_to :question

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'is_closed', 'position', 'color'

  validates :name, presence: true, uniqueness: true

  scope :sorted, lambda { order(:position) }

  rcrm_acts_as_list

  def to_s
    name
  end
end
