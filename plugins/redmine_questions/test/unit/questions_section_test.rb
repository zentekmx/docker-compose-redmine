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

class QuestionsSectionTest < ActiveSupport::TestCase
  fixtures :questions, :questions_sections

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:questions, :questions_sections])

  def test_relations
    assert questions_sections(:section_001).questions
  end

  def test_to_s
    assert_equal questions_sections(:section_001).name, questions_sections(:section_001).to_s
  end

  def test_l_type
    assert_equal "Questions", questions_sections(:section_001).l_type
    I18n.locale = "es"
    assert_equal "Questions", questions_sections(:section_001).l_type
  end
end
