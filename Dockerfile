FROM bitnami/redmine:4.1.1

RUN install_packages build-essential libpq-dev libmagickwand-dev psutils vim tzdata

WORKDIR /opt/bitnami/redmine
RUN mkdir -p /bitnami/redmine/public/themes

RUN ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
RUN echo "America/Mexico_City" > /etc/timezone

COPY ./plugins/redmine_omniauth_saml /opt/bitnami/redmine/plugins/redmine_omniauth_saml
COPY ./plugins/redmine_xls_export /opt/bitnami/redmine/plugins/redmine_xls_export
COPY ./plugins/redmine_issues_tree /opt/bitnami/redmine/plugins/redmine_issues_tree
COPY ./plugins/redmine_slack /opt/bitnami/redmine/plugins/redmine_slack
COPY ./plugins/redmine_dashboard /opt/bitnami/redmine/plugins/redmine_dashboard
COPY ./plugins/redmine_agile /opt/bitnami/redmine/plugins/redmine_agile
COPY ./plugins/redmine_questions /opt/bitnami/redmine/plugins/redmine_questions
COPY ./plugins/redmine_favorite_projects /opt/bitnami/redmine/plugins/redmine_favorite_projects
COPY ./plugins/redmine_resources /opt/bitnami/redmine/plugins/redmine_resources
COPY ./plugins/redmine_people /opt/bitnami/redmine/plugins/redmine_people
COPY ./plugins/redmineup_tags /opt/bitnami/redmine/plugins/redmineup_tags
COPY ./plugins/redmine_spent_time /opt/bitnami/redmine/plugins/redmine_spent_time
COPY ./plugins/redmine_checklists /opt/bitnami/redmine/plugins/redmine_checklists
COPY ./plugins/redmine_lightbox2 /opt/bitnami/redmine/plugins/redmine_lightbox2
COPY ./plugins/progressive_projects_list /opt/bitnami/redmine/plugins/progressive_projects_list
COPY ./plugins/circle /opt/bitnami/redmine/public/themes/circle
COPY ./plugins/highrise /opt/bitnami/redmine/public/themes/highrise
COPY ./saml.rb /opt/bitnami/redmine/config/saml.rb

RUN bundle config unset deployment
RUN bundle install
