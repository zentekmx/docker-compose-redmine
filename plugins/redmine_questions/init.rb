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

requires_redmine_crm version_or_higher: '0.0.41'

require 'redmine_questions'

QA_VERSION_NUMBER = '1.0.2'
QA_VERSION_TYPE = "Light version"

Redmine::Plugin.register :redmine_questions do
  name "Redmine Q&A plugin (#{QA_VERSION_TYPE})"
  author 'RedmineUP'
  description 'This is a Q&A plugin for Redmine'
  version QA_VERSION_NUMBER 
  url 'https://www.redmineup.com/pages/plugins/questions'
  author_url 'mailto:support@redmineup.com'

  requires_redmine :version_or_higher => '2.6'

  delete_menu_item(:top_menu, :help)

  menu :top_menu, :questions, {controller: 'questions_sections', action: 'index', project_id: nil},
    caption: :label_questions,
    if: Proc.new {User.current.allowed_to?({controller: 'questions_sections', action: 'index'}, nil, {global: true})}

  menu :project_menu, :questions, {controller: 'questions_sections', action: 'index'},
    param: :project_id

  project_module :questions do
    permission :add_questions, { questions: [:create, :new, :preview, :update_form] }
    permission :edit_questions, { questions: [:edit, :update, :preview, :update_form], questions_answers: [:edit, :update, :preview] }, require: :loggedin
    permission :edit_own_questions, {questions: [:edit, :update, :preview, :update_form]}, require: :loggedin
    permission :edit_own_answers, {questions_answers: [:edit, :update, :preview]}, require: :loggedin
    permission :add_answers, { questions_answers: [:create, :show, :new, :edit, :update, :preview] }
    permission :view_questions, { questions: [:index, :show, :autocomplete_for_subject], questions_sections: [:index] }, read: true
    permission :delete_questions, { questions: [:destroy] }, require: :loggedin
    permission :delete_answers, { questions_answers: [:destroy] }, require: :loggedin
    permission :vote_questions, { questions_votes: [:create] }
    permission :accept_answers, { questions_answers: [:update] }, require: :loggedin
    permission :comment_question, { questions_comments: [:create] }
    permission :edit_question_comments, { questions_comments: [:update, :destroy, :edit] }, require: :loggedin
    permission :edit_own_question_comments, { questions_comments: [:update, :destroy, :edit] }, require: :loggedin
    permission :manage_sections, { projects: :settings, questions_sections: [:create, :new, :edit, :update] }, require: :loggedin
    permission :create_tags, {}
  end

  activity_provider :questions, default: false, class_name: ['Question', 'QuestionsAnswer']

  Redmine::Search.map do |search|
    search.register :questions
  end  
end
