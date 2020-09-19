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
    module MailerPatch

      module ClassMethods
        def deliver_question_comment_added(comment)
          question_comment_added(User.current, comment).deliver_later
        end
      end

      module InstanceMethods
        def question_comment_added(_user = User.current, comment)
          question = comment.commented.is_a?(Question) ? comment.commented : comment.commented.question
          @question_url = url_for(:controller => 'questions', :action => 'show', :id => question.id)
          project_identifier = question.project.try(:identifier)
          redmine_headers 'Project' => project_identifier, 'Question-Id' => question.id
          message_id comment
          @author = comment.author
          @comment = comment
          @question = question
          project_prefix = [project_identifier, question.section_name, "q&a#{question.id}"].compact.join(' - ')
          recipients = question.watcher_recipients
          mail :to => recipients,
               :subject => "[#{project_prefix}] RE: #{question.subject}"
        end

        def question_question_added(_user = Current.user, question)
          @question_url = url_for(:controller => 'questions', :action => 'show', :id => question.id)
          project_identifier = question.project.try(:identifier)
          redmine_headers 'Project' => project_identifier, 'Question-Id' => question.id
          message_id question
          @author = question.author
          @question = question
          recipients = question.notified_users
          cc = question.section.notified_watchers - recipients
          project_prefix = [project_identifier, question.section_name, "q&a#{question.id}"].compact.join(' - ')
          mail :to => recipients,
               :cc => cc,
               :subject => "[#{project_prefix}] #{question.subject}"
        end

        def question_answer_added(_user = Current.user, answer)
          question = answer.question
          @question_url = url_for(controller: 'questions', action: 'show', id: question.id)
          project_identifier = question.project.try(:identifier)
          redmine_headers 'Project' => project_identifier, 'Question-Id' => question.id
          message_id question
          recipients = question.notified_users
          watchers = (question.notified_watchers + question.section.notified_watchers).uniq
          watchers = watchers.map(&:mail) if watchers.first.respond_to?(:mail)
          cc = watchers - recipients

          @author = answer.author
          @answer = answer
          @question = question
          project_prefix = [project_identifier, question.section_name, "q&a#{question.id}"].compact.join(' - ')
          mail to: recipients,
               cc: cc,
               subject: "[#{project_prefix}] - answ##{answer.id} - RE: #{question.subject}"
        end
      end

      def self.included(receiver)
        receiver.send :extend, ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
        end
      end
    end
  end
end

unless Mailer.included_modules.include?(RedmineQuestions::Patches::MailerPatch)
  Mailer.send(:include, RedmineQuestions::Patches::MailerPatch)
end
