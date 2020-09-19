module RedmineLightbox2
  module Hooks
    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        if context[:controller] && (  context[:controller].is_a?(IssuesController) ||
                                      (Object.const_defined?('DmsfController') && context[:controller].is_a?(DmsfController)) ||
                                      (Object.const_defined?('ContactsController') && context[:controller].is_a?(ContactsController)) ||
                                      (Object.const_defined?('ArticlesController') && context[:controller].is_a?(ArticlesController)) ||
                                      context[:controller].is_a?(WikiController) ||
                                      context[:controller].is_a?(DocumentsController) ||
                                      context[:controller].is_a?(FilesController) ||
                                      context[:controller].is_a?(MessagesController) ||
                                      context[:controller].is_a?(NewsController))
          return stylesheet_link_tag("jquery.fancybox-3.5.7.min.css", :plugin => "redmine_lightbox2", :media => "screen") +
            stylesheet_link_tag("lightbox.css", :plugin => "redmine_lightbox2", :media => "screen") +
            javascript_include_tag('jquery.fancybox-3.5.7.min.js', :plugin => 'redmine_lightbox2') +
            javascript_include_tag('lightbox.js', :plugin => 'redmine_lightbox2')
        else
          return ''
        end
      end
    end
  end
end
