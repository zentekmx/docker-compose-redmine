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
    module CommentPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          if method_defined?(:send_notification)
            alias_method :send_notification_without_questions, :send_notification
            alias_method :send_notification, :send_notification_with_questions
          end
        end
      end

      module InstanceMethods
        def send_notification_with_questions
          if [Question, QuestionsAnswer].include?(commented.class)
            if Setting.notified_events.include?('question_comment_added')
              Mailer.send('question_comment_added', self).deliver
            end
          else
            send_notification_without_questions
          end
        end
      end
    end
  end
end

unless Comment.included_modules.include?(RedmineQuestions::Patches::CommentPatch)
  Comment.send(:include, RedmineQuestions::Patches::CommentPatch)
end
