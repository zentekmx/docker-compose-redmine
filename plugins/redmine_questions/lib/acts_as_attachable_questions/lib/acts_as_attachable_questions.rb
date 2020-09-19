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

module Redmine
  module Acts
    module AttachableQuestions
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_attachable_questions(options = {})
          if ActiveRecord::VERSION::MAJOR >= 4
            has_many :attachments, lambda { order("#{Attachment.table_name}.created_on") }, options.merge(:as => :container,
                                                 :dependent => :destroy)
          else
            has_many :attachments, options.merge(:as => :container,
                                                 :order => "#{Attachment.table_name}.created_on",
                                                 :dependent => :destroy)
          end

          send :include, Redmine::Acts::AttachableQuestions::InstanceMethods
          before_save :attach_saved_attachments
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def attachments_visible?(user = User.current)
          respond_to?(:visible?) ? visible?(user) : true
        end

        def attachments_editable?(user = User.current)
          (respond_to?(:visible?) ? visible?(user) : true) &&
            (user.allowed_to?(:manage_sections, project, :global => true) ||
              user.allowed_to?(:add_questions, project, :global => true))
        end

        def attachments_deletable?(user = User.current)
          (respond_to?(:visible?) ? visible?(user) : true) &&
            (user.allowed_to?(:delete_questions, project, :global => true) ||
              user.allowed_to?(:add_questions, project, :global => true))
        end

        def saved_attachments
          @saved_attachments ||= []
        end

        def unsaved_attachments
          @unsaved_attachments ||= []
        end

        def save_attachments(attachments, author = User.current)
          attachments = attachments.to_unsafe_hash if attachments.respond_to?(:to_unsafe_hash)
          attachments = attachments.values if attachments.is_a?(Hash)
          if attachments.is_a?(Array)
            attachments.each do |attachment|
              a = nil
              if file = attachment['file']
                next unless file.size > 0
                a = Attachment.create(:file => file, :author => author)
              elsif token = attachment['token']
                a = Attachment.find_by_token(token)
                next unless a
                a.filename = attachment['filename'] unless attachment['filename'].blank?
                a.content_type = attachment['content_type']
              end
              next unless a
              a.description = attachment['description'].to_s.strip
              if a.new_record?
                unsaved_attachments << a
              else
                saved_attachments << a
              end
            end
          end
          { :files => saved_attachments, :unsaved => unsaved_attachments }
        end

        def attach_saved_attachments
          saved_attachments.each do |attachment|
            attachments << attachment
          end
        end
        module ClassMethods
        end
      end
    end
  end
end
