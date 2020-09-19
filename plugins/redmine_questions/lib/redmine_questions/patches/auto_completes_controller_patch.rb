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

require_dependency 'auto_completes_controller'

module RedmineQuestions
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
        end
      end

      module InstanceMethods
        def questions_tags
          @names_only = params[:names]
          @questions_tags = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Question.tags_cloud(:name_like => q, :limit => params[:limit] || 10)
          @questions_tags = scope.to_a.sort! { |x, y| x.name <=> y.name }
          render :layout => false, :partial => 'questions_tags'
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineQuestions::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineQuestions::Patches::AutoCompletesControllerPatch)
end
