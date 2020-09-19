Redmine Lightbox 2
==================

This plugin lets you preview image (JPG, GIF, PNG, BMP) and PDF attachments in a lightbox.

This is a fork of zipme's [redmine_lightbox](https://github.com/zipme/redmine_lightbox) plugin.

*This plugin is listed in the [Redmine plugin directory](http://www.redmine.org/plugins/redmine_lightbox2)*


Compatibility
-------------

**The latest version on `master` branch supports Redmine 4.0 only!**

A Redmine 3.4.x compatible version can be found on the [redmine-3.4](https://github.com/paginagmbh/redmine_lightbox2/tree/redmine-3.4) branch.

A Redmine 3.3.x compatible version can be found on the [redmine-3.3](https://github.com/paginagmbh/redmine_lightbox2/tree/redmine-3.3) branch.

A Redmine 3.0, 3.1, 3.2 compatible version can be found on the [redmine-3.0-3.2](https://github.com/paginagmbh/redmine_lightbox2/tree/redmine-3.0-3.2) branch.

A Redmine 2.6.x compatible version can be found on the [redmine-2.6](https://github.com/paginagmbh/redmine_lightbox2/tree/redmine-2.6) branch.

A Redmine 2.0 - 2.5.x compatible version can be found on the [redmine-2.5-and-lower](https://github.com/paginagmbh/redmine_lightbox2/tree/redmine-2.5-and-lower) branch.

For older version please download [this package](https://github.com/paginagmbh/redmine_lightbox2/zipball/7cd1d66d54f267015dcd0b0d0eadab251918de1d)


Installation and Setup
----------------------

* Clone or [download](https://github.com/paginagmbh/redmine_lightbox2/releases) this repo into your **redmine_root/plugins/** folder
```
$ git clone https://github.com/paginagmbh/redmine_lightbox2.git
```
* If you downloaded a tarball / zip from master branch, make sure you rename the extracted folder to `redmine_lightbox2`
* You have to run the plugin rake task to provide the assets (from the Redmine root directory):
```
$ rake redmine:plugins:migrate RAILS_ENV=production
```
* Restart Redmine


License
-------

*redmine_lightbox2* plugin is developed under the [MIT License](LICENSE).
