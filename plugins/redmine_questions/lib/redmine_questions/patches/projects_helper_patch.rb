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

require_dependency 'queries_helper'

module RedmineQuestions
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :project_settings_tabs_without_questions, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_questions
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_questions
          tabs = project_settings_tabs_without_questions

          tabs.push({ :name => 'questions',
            :action => :manage_sections,
            :partial => 'projects/questions_settings',
            :label => :label_questions }) if User.current.allowed_to?(:manage_sections, @project)
          tabs

        end
      end

    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineQuestions::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineQuestions::Patches::ProjectsHelperPatch)
end
