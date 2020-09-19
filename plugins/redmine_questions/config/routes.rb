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

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# match '/news/:id/comments', :to => 'comments#create', :via => :post
# match '/news/:id/comments/:comment_id', :to => 'comments#destroy', :via => :delete
resources :questions do
  collection do
    put :preview
    put :update_form
    # match :preview, :to => 'questions#preview', :via => [:get, :put, :post]
    get :autocomplete_for_subject
    get :topics
    get :index_public
  end
  member do
    get :from_issue
    # post :new_comment
  end
  resources :questions_answers, :as => :answers
end

resources :questions_answers, :except => [:show, :index] do
  collection do
    put :preview
  end
end

match "questions_votes", :to => 'questions_votes#create', :via => [:get, :post], :as => 'questions_votes'

resources :questions_comments do
  member do
    post :update
  end
end

resources :questions_sections
resources :questions_statuses, :except => :show

resources :projects do
  resources :questions_sections
  resources :questions
end

match "projects/:project_id/questions/questions_sections/:section_id" => "questions#index", :via => [:get]
match "questions/questions_sections/:section_id" => "questions#index", :via => [:get]
match 'auto_completes/questions_tags' => 'auto_completes#questions_tags', :via => :get, :as => 'auto_complete_questions_tags'
