0.0.20
---
* Make plugin compatibility with Redmine 5.0.x

0.0.19
---
* Italian translation
* Fix logger and use new setting
* Do not send on private-notes
* Fix reopening closed issue error
* Improve de locale
* Fix typo in email_was_send_to_supportclient
* Sets To header optional
* Remove Gemfile.lock
* Find and process value of custom field directly
* Add X-Redmine-Issue-Tracker header to mailerpatch

0.0.18
---
* Remove batches as nobody has the time to fix the tests
* Remove untrue stuff from readme
* Update mail_handler_patch.rb
* Fix migration
* Incorrect issue and project ids usage
* Add space after the pre

0.0.17
---
* Fix issue by sending redmine journals with redmine_helpdesk
* Store email-details before each note by martincizek from orchitech
* Make option to reopen closed issues by email work
* Added support for reply separator by sandratatarevicova from orchitech

0.0.16
---
* Make plugin compatibility with Redmine 4.0.x
* Add option to reopen closed issues by email

0.0.15
---
* Added support for tracking email details by martincizek from orchitech

0.0.14
---
* Make plugin compatibility with Redmine 3.0.1 by Vilppu Vuorinen

0.0.13
---
* Unit and functional tests with travis and code climate support by Vilppu Vuorinen
* Add customizable email footers by martincizek
* Test compatibility with Redmine 2.6.2

0.0.12
---
* Add support for non-anonymous supportclients by martincizek
* Add issue matching based on standard MIME header references by martincizek
* Test compatibility with Redmine 2.5.3

0.0.11
---
* Make sure that the notes length is always calculated

0.0.10
---
* Fixed bug trying to send an email with empty notes

0.0.9
---
* Fixed non-working helpdesk-send-to-owner-default checkbox

0.0.8
---
* Add setting for handling send to owner default value by davidef

0.0.7
---
* Added reply-to header by barbazul

0.0.6
---
* Update code for redmine 2.4.x by Craig Gowing
* Minor compatibility issues fixed

0.0.5
---
* Fix skip validation issue 

0.0.4
---
* Update code for redmine 2.3.x
* Send any journal attachments with the email notification to the supportclient

0.0.3
---
* The sender email-address is now adjustable on a per project basis

0.0.2
---
* A standard first reply message can be send to the supportclient on ticket creation (optional, per project)
* The email-footer for the email notification to the supportclient can be adjusted (optional, per project)

0.0.1
---
* First release