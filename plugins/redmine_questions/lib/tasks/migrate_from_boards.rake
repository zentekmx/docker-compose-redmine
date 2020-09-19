namespace :redmine do
  namespace :questions do
    desc <<-END_DESC
Migrate forum board to questions section

  rake redmine:questions:migrate_board_to_section RAILS_ENV="production" board_id="source forum board id" question_section_id="destination question section id" project_id="section project id (nil for global section)"

END_DESC

    task :migrate_board_to_section => :environment do
      board_id              = ENV['board_id']
      question_section_id   = ENV['question_section_id']
      question_section_name = ENV['question_section_name']
      project_id            = ENV['project_id']

      if board_id.blank? && project_id.blank?
        puts 'RedmineQuestions: Params board_id or project_id should be present'
        exit
      end

      project = Project.where(:identifier => project_id).first
      project.enable_module!(:questions) if project
      boards = [Board.where(:id => board_id).first].compact
      boards = project.boards if project && boards.blank?
      boards.each do |board|
        section = QuestionsSection.for_project(project).where(:id => question_section_id).first
        section ||= QuestionsSection.for_project(project).find_or_create_by(:name => question_section_name) if question_section_name
        section ||= QuestionsSection.for_project(project).find_or_create_by(:name => board.name)
        if section.nil? || board.nil?
          puts 'RedmineQuestions: Destination section does not found' unless section
          puts 'RedmineQuestions: Source board does not found' unless board
          exit
        end

        board.topics.reverse.each do |topic|
          if section.questions.where(:subject => topic.subject).first.present?
            puts "Questions with subject #{topic.subject} already exists."
            next
          end

          question_attrs = topic.attributes.slice('subject', 'content', 'author_id', 'locked')
          migrated_question = section.questions.create(question_attrs)
          migrated_question.attachments = topic.attachments.map { |attachment| attachment.copy }

          topic.children.each do |reply|
            if section.section_type == 'questions'
              answer_attrs = reply.slice('subject', 'content', 'author_id', 'locked')
              migrated_answer = migrated_question.answers.create(answer_attrs)
              migrated_answer.attachments = reply.attachments.map { |attachment| attachment.copy }
            else
              comment_attrs = { 'author_id' => reply.author_id, 'comments' => reply.content }
              migrated_question.comments.create(comment_attrs)
            end
          end
        end
      end #each
    end
  end
end
