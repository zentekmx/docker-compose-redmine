require 'redmine'

require_dependency 'patches/attachments_patch'
require_dependency 'hooks/view_layouts_base_html_head_hook'

Redmine::Plugin.register :redmine_lightbox2 do
  name 'Redmine Lightbox 2'
  author 'Tobias Fischer'
  description 'This plugin lets you preview image and pdf attachments in a lightbox.'
  version '0.5.1'
  url 'https://github.com/paginagmbh/redmine_lightbox2'
  author_url 'https://github.com/tofi86'
  requires_redmine :version_or_higher => '4.0'
end



# Patches to the Redmine core.
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

if Rails::VERSION::MAJOR >= 5
  ActiveSupport::Reloader.to_prepare do
    require_dependency 'attachments_controller'
    AttachmentsController.send(:include, RedmineLightbox2::AttachmentsPatch)
  end
elsif Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'attachments_controller'
    AttachmentsController.send(:include, RedmineLightbox2::AttachmentsPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'attachments_controller'
    AttachmentsController.send(:include, RedmineLightbox2::AttachmentsPatch)
  end
end
