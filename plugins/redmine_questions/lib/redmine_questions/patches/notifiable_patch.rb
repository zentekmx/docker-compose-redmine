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

module RedmineQuestions
  module Patches
    module NotifiablePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          unloadable
          class << self
            alias_method :all_without_questions, :all
            alias_method :all, :all_with_questions
          end
        end
      end

      module ClassMethods
        def all_with_questions
          notifications = all_without_questions
          notifications << Redmine::Notifiable.new('question_added')
          notifications << Redmine::Notifiable.new('question_answer_added')
          notifications << Redmine::Notifiable.new('question_comment_added')
          notifications
        end
      end
    end
  end
end

unless Redmine::Notifiable.included_modules.include?(RedmineQuestions::Patches::NotifiablePatch)
  Redmine::Notifiable.send(:include, RedmineQuestions::Patches::NotifiablePatch)
end
