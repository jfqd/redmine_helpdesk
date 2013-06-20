# Redmine Helpdesk

Lightweight helpdesk plugin for redmine. Adds the email sender-address of an anonymous supportclient to the custom field 'owner-email' of a ticket which was created by a support email. Answers can be send to the supportclient by checking the support checkbox on a journal.

## Features

* No need to create any user accounts for anonymous user
* Support for sending an email notification to the (anonymous user) supportclient on ticket creation
* A standard first reply message can be send to the supportclient on ticket creation (optional, per project)
* The email-footer for the email notification to the supportclient can be adjusted (optional, per project)
* The sender email-address can be adjusted (optional, per project)
* Internal communication is not send to the supportclient
* The supportclient will get an email notification if the support checkbox on the journal is checked

## Screenshot

![Send mail to supportclient](doc/send-mail-to-supportclient.jpg "New checkbox 'Send mail to supportclient'")

## Getting the plugin

A copy of the plugin can be downloaded from GitHub: http://github.com/jfqd/redmine_helpdesk

## Installation

To install the plugin clone the repro from github and migrate the database:

```
cd <into your redmine root directory>
git clone git://github.com/jfqd/redmine_helpdesk.git vendor/plugins/redmine_helpdesk
rake db:migrate_plugins RAILS_ENV=production
```

To uninstall the plugin migrate the database back and remove the plugin:

```
cd <into your redmine root directory>
rake db:migrate:plugin NAME=redmine_helpdesk VERSION=0 RAILS_ENV=production
rm -rf vendor/plugin/redmine_helpdesk
```

Further information about plugin installation can be found at: http://www.redmine.org/wiki/redmine/Plugins

## Usage

To use the helpdesk functionality you need to

* add the custom field 'owner-email' to a project in the project configuration
* add a standard first reply message into the custom_field 'helpdesk-first-reply' in the project configuration (optional)
* add an email-footer into the custom_field 'helpdesk-email-footer' in the project configuration (optional)
* make sure 'Issue added' and 'Issue updated' in the general redmine settings for email notifications are checked
* add a cronjob for creating issues from support emails

## Cronjob

Creating tickets from support emails through an IMAP-account is done by a cronjob. The following syntax is for ubuntu linux:

```
*/5 * * * * redmine /usr/bin/rake -f /path/to/redmine/Rakefile --silent redmine:email:receive_imap RAILS_ENV="production" host=mail.example.com port=993 username=username password=password ssl=true project=project_identifier folder=INBOX move_on_success=processed move_on_failure=failed no_permission_check=1 unknown_user=accept 1 > /dev/null
```

Further information about receiving emails with redmine can be found at: http://www.redmine.org/projects/redmine/wiki/RedmineReceivingEmails

## Compatibility

The latest version of this plugin is only compatible with Redmine 2.3.x.

A version for Redmine 1.2.x. up to 1.4.7. ist tagged with [v1.4](https://github.com/jfqd/redmine_helpdesk/tree/v1.4 "plugin version for Redmine 1.2.x up to 1.4.7") and available for [download on github](https://github.com/jfqd/redmine_helpdesk/archive/v1.4.zip "download plugin for Redmine 1.2.x up to 1.4.7").

## License

This plugin is licensed under the MIT license. See LICENSE-file for details.

## Copyright

Copyright (c) 2012-2013 Stefan Husch, qutic development. The development has been fully sponsored by netz98.de
