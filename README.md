# Redmine Helpdesk

[![Build Status](https://travis-ci.org/jfqd/redmine_helpdesk.svg?branch=master)](https://travis-ci.org/jfqd/redmine_helpdesk) [![Code Climate](https://codeclimate.com/github/jfqd/redmine_helpdesk/badges/gpa.svg)](https://codeclimate.com/github/jfqd/redmine_helpdesk) [![Test Coverage](https://codeclimate.com/github/jfqd/redmine_helpdesk/badges/coverage.svg)](https://codeclimate.com/github/jfqd/redmine_helpdesk)

Lightweight helpdesk plugin for redmine. Adds the email sender-address of an anonymous supportclient to the custom field 'owner-email' of a ticket which was created by a support email. Answers can be send to the supportclient by checking the support checkbox on a journal.

## Features

* No need to create any user accounts for anonymous user
* Support for sending an email notification to the (anonymous user) supportclient on ticket creation
* A standard first reply message can be send to the supportclient on ticket creation (optional, per project)
* The email-footer for the email notification to the supportclient can be adjusted (optional, per project)
* The email-footer can be customized by using the following placeholders: %USER_FIRST_NAME%, %USER_LAST_NAME%, %USER_EMAIL%, %USER_LOGIN%, %USER_CF_...% for all user custom fields
* The sender email-address can be adjusted (optional, per project)
* Internal communication is not send to the supportclient
* The supportclient will get an email notification if the support checkbox on the journal is checked
* Journal attachments will be delivered too

## Screenshot

![Send mail to supportclient](doc/send-mail-to-supportclient.jpg "New checkbox 'Send mail to supportclient'")

## Getting the plugin

A copy of the plugin can be downloaded from GitHub: http://github.com/jfqd/redmine_helpdesk

## Installation

To install the plugin clone the repo from github and migrate the database:

```
cd /path/to/redmine/
git clone git://github.com/jfqd/redmine_helpdesk.git plugins/redmine_helpdesk
rake redmine:plugins:migrate RAILS_ENV=production
```

To uninstall the plugin migrate the database back and remove the plugin:

```
cd /path/to/redmine/
rake redmine:plugins:migrate NAME=redmine_helpdesk VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_helpdesk
```

Further information about plugin installation can be found at: http://www.redmine.org/wiki/redmine/Plugins

## Usage

To use the helpdesk functionality you need to

* add the custom field 'owner-email' to a project in the project configuration
* add a standard first reply message into the custom_field 'helpdesk-first-reply' in the project configuration (optional)
* add an email-footer into the custom_field 'helpdesk-email-footer' in the project configuration
* add a sender email address into the custom_field 'helpdesk-sender-email' in the project configuration (optional)
* make sure 'Issue added' and 'Issue updated' in the general redmine settings for email notifications are checked
* add the permission 'Treat as supportclient' to all roles you want to be treated as supportclient (the permission is automatically added to the 'Anonymous' role)
* disable standard notifications for non-anonymous supportclients to prevent their spamming (optional)
* add a cronjob for creating issues from support emails

![project configuration sample](doc/project-settings.jpg "Per project configuration sample")

## Cronjob

Creating tickets from support emails through an IMAP-account is done by a cronjob. The following syntax is for ubuntu or debian linux:

```
*/5 * * * * redmine /usr/bin/rake -f /path/to/redmine/Rakefile --silent redmine:email:receive_imap RAILS_ENV="production" host=mail.example.com port=993 username=username password=password ssl=true project=project_identifier folder=INBOX move_on_success=processed move_on_failure=failed no_permission_check=1 unknown_user=accept 1 > /dev/null
```

Further information about receiving emails with redmine can be found at: [http://www.redmine.org/projects/redmine/wiki/RedmineReceivingEmails](http://www.redmine.org/projects/redmine/wiki/RedmineReceivingEmails#Fetching-emails-from-an-IMAP-server)

Please note that forwarding emails with rdm-mailhandler.rb is currently not supported by the plugin.

## Compatibility

The latest version of this plugin is only compatible with Redmine 2.4.x., 2.5.x, 2.6.x, 3.0.x.

If you prefer to run Redmine with JRuby make sure to use Redmine versions prior to 3.0.x!

* A version for Redmine 1.2.x. up to 1.4.7. is tagged with [v1.4](https://github.com/jfqd/redmine_helpdesk/tree/v1.4 "plugin version for Redmine 1.2.x up to 1.4.7") and available for [download on github](https://github.com/jfqd/redmine_helpdesk/archive/v1.4.zip "download plugin for Redmine 1.2.x up to 1.4.7").
* A version for Redmine 2.3.x is tagged with [v2.3](https://github.com/jfqd/redmine_helpdesk/tree/v2.3 "plugin version for Redmine 2.3.x") and available for [download on github](https://github.com/jfqd/redmine_helpdesk/archive/v2.3.zip "download plugin for Redmine 2.3.x").
* A version for Redmine 2.4.x and 2.5.x is tagged with [v2.5](https://github.com/jfqd/redmine_helpdesk/releases/tag/v2.5 "plugin version for Redmine 2.4.x and 2.5.x") and available for [download on github](https://github.com/jfqd/redmine_helpdesk/archive/v2.5.zip "download plugin for Redmine 2.4.x and 2.5.x").


## Contribution

* [monaka](https://github.com/monaka) - Japanese translation
* [avoidik](https://github.com/avoidik) - Add missed Russian translation into roles and access manager
* [WhereIsPedro](https://github.com/WhereIsPedro) - Polish translation
* [vilppuvuorinen](https://github.com/vilppuvuorinen) - 3.0.x compatibility
* [vilppuvuorinen](https://github.com/vilppuvuorinen) - Unit and functional tests with travis and code climate support
* [ssidelnikov](https://github.com/ssidelnikov) - Make sure that the notes length is always calculated
* [nifuki](https://github.com/nifuki) - Fixed bug trying to send an email with empty notes
* [nifuki](https://github.com/nifuki) - Fixed non-working helpdesk-send-to-owner-default checkbox
* [box789](https://github.com/box789) - Russian translation
* [seqizz](https://github.com/seqizz) - Turkish translation
* [benstwa](https://github.com/benstwa) - 'send' should be 'sent'
* [davidef](https://github.com/davidef) - Add setting for handling sent to owner default value
* [Craig Gowing](https://github.com/craiggowing) - Redmine 2.4 compatibility
* [Barbazul](https://github.com/barbazul) - Added reply-to header
* [Orchitech Solutions](https://github.com/orchitech) - Added issue matching based on standard MIME header references
* [Orchitech Solutions](https://github.com/orchitech) - Added support for non-anonymous supportclients (sponsored by ISIC Global Office)
* [Orchitech Solutions](https://github.com/orchitech) - Added support for customizable email footers (sponsored by ISIC Global Office)
* [Orchitech Solutions](https://github.com/orchitech) - Added support for tracking email details (sponsored by ISIC Global Office)

## License

This plugin is licensed under the MIT license. See LICENSE-file for details.

## Copyright

Copyright (c) 2012-2015 Stefan Husch, qutic development. The start of development has been sponsored by netz98.de
