# Redmine Mail Delivery Compat3

This plugin provides a mail send per notification event like Redmine3.

## Installation

1. Download plugin in Redmine plugin directory.

   ```sh
   git clone https://github.com/9506hqwy/redmine_mail_delivery_compat3.git
   ```

2. Start Redmine

## Configuration

1. Enable plugin module.

   Check [Mail Delivery Compat3] in project setting.

## Tested Environment

* Redmine (Docker Image)
  * 4.1
  * 4.2
  * 5.0
  * 5.1
  * 6.0
  * 6.1
* Database
  * SQLite
  * MySQL 5.7 or 8.0
  * PostgreSQL 14

## Notes

This plugin has same problems as Redmine3. see [#26791](https://www.redmine.org/issues/26791).

## References

* [#26791 Send individual notification mails per mail recipient](https://www.redmine.org/issues/26791)
* [#30929 No longer all receivers are shown in "to" field after upgrade from 3.4.7 to 4.0.0](https://www.redmine.org/issues/30929)
