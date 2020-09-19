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

class CreateQuestions < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :questions do |t|
      t.string :subject
      t.text :content
      t.references :section, :index => true
      t.references :status, :index => true
      t.references :author, :index => true
      t.boolean :featured, :default => false
      t.boolean :locked, :default => false
      t.integer :cached_weighted_score, :default => 0
      t.integer :comments_count, :default => 0
      t.integer :answers_count, :default => 0
      t.integer :views, :default => 0
      t.integer :total_views, :default => 0
      t.datetime :created_on
      t.datetime :updated_on
    end
  end
end
