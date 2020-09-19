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

module QuestionsHelper
  def question_status_tag(status)
    return '' unless status
    content_tag(:span, status.name, :class => 'question-status-tag tag-label-color', :style => "background-color: #{status.color}")
  end

  def allow_voting?(votable, user = User.current)
    (votable.author == user && QuestionsSettings.vote_own? || votable.author != user) &&
      user.allowed_to?(:vote_questions, votable.project)
  end

  def question_breadcrumb(item)
    links = []
    links << link_to(l(:label_questions), { :controller => 'questions_sections', :action => 'index', :project_id => nil})
    links << link_to(item.project.name, { :controller => 'questions_sections', :action => 'index', :project_id => item.project }) if item && item.project
    links << link_to(item.section.name, { :controller => 'questions', :action => 'index', :project_id => item.project, :section_id => item.section }) if item && item.is_a?(Question) && item.section.present?
    breadcrumb links
  end

  def global_modificator
    return {:global => true} if !@project
    {}
  end

  def path_to_sections
    return project_questions_sections_path if @project
    questions_sections_path
  end

end
