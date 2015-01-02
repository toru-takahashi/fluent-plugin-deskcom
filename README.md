Deskcom plugin for Fluentd
===========================

Fluentd Input plugin to collect data from Your Deskcom.
It is useful to improve your support quality.
This plugin is still experimental.
This plugin depends on [desk library](https://github.com/chriswarren/desk)
Also, please see [Desk API v2](http://dev.desk.com/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-deskcom'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-deskcom

## Usage

### Cases Config Sample

```ruby
<source>
  type                deskcom
  subdomain           DESKCOM_SUBDOMAIN           # Required (<subdomain>.desk.com)
  consumer_key        DESKCOM_CONSUMER_KEY        # Required
  consumer_secret     DESKCOM_CONSUMER_SECRET     # Required
  oauth_token         DESKCOM_OAUTH_TOKEN         # Required
  oauth_token_secret  DESKCOM_OAUTH_TOKEN_SECRET  # Required
  store_file          /var/log/cases.yml          # Optional (filepath)
  output_format       simple                      # Optional (simple(default))
  input_api           cases                       # Optional (cases(default) or replies)
  tag                 deskcom.cases               # Required
  time_format         updated_at                  # Optional
</source>
```

```ruby
{
    "id": 150,
    "blurb": ": "",
    "priority": 4,
    "external_id": null,
    "locked_until": null,
    "label_ids": [],
    "active_at": null,
    "changed_at": "2013-02-10T14:18:56Z",
    "created_at": "2013-01-15T11:12:20Z",
    "updated_at": "2013-02-10T14:18:56Z",
    "first_opened_at": null,
    "opened_at": null,
    "first_resolved_at": "2013-01-27T13:54:13Z",
    "resolved_at": "2013-01-27T13:54:13Z",
    "status": "closed",
    "description": null,
    "language": null,
    "received_at": "2013-01-15T11:12:20Z",
    "type": "email",
    "labels": [],
    "subject": "Chat transcript: no operator and Japan #6642",
    "custom_fields": "{\"custom1_\":null,\"custom2_\":null}"
}
```

### Replies Config Sample

```ruby
<source>
  type                deskcom
  subdomain           DESKCOM_SUBDOMAIN           # Required (<subdomain>.desk.com)
  consumer_key        DESKCOM_CONSUMER_KEY        # Required
  consumer_secret     DESKCOM_CONSUMER_SECRET     # Required
  oauth_token         DESKCOM_OAUTH_TOKEN         # Required
  oauth_token_secret  DESKCOM_OAUTH_TOKEN_SECRET  # Required
  store_file          /var/log/replies.yml          # Optional (filepath)
  output_format       simple                      # Optional (simple(default))
  input_api           replies                     # Optional (cases(default) or replies)
  tag                 deskcom.replies               # Required
</source>
```

```ruby
{
    "case_id": 1
    "id": 159057281,
    "created_at": "2013-01-14T22:18:14Z",
    "updated_at": "2013-01-14T22:18:14Z",
    "sent_at": null,
    "erased_at": null,
    "hidden_by": null,
    "hidden_at": null,
    "body": "",
    "from": "Toru Takahashi <torutakahashi.ayashi@gmail.com>",
    "to": "\"test user\" <test@user.co.jp>",
    "cc": "",
    "bcc": null,
    "client_type": "apple_mail",
    "direction": "in",
    "status": "received",
    "subject": "subject",
    "hidden": false
}
```

### Config Sample (Deskcom -> TreasureData)

```ruby
# fluent.conf
<source>
  type                deskcom
  subdomain           DESKCOM_SUBDOMAIN           # Required (<subdomain>.desk.com)
  consumer_key        DESKCOM_CONSUMER_KEY        # Required
  consumer_secret     DESKCOM_CONSUMER_SECRET     # Required
  oauth_token         DESKCOM_OAUTH_TOKEN         # Required
  oauth_token_secret  DESKCOM_OAUTH_TOKEN_SECRET  # Required
  store_file          /var/log/cases.yml          # Optional (filepath)
  output_format       simple                      # Optional (simple(default))
  input_api           cases                       # Optional (cases(default) or replies)
  tag                 deskcom.cases               # Required
  time_column         updated_at
</source>

<source>
  type                deskcom
  subdomain           DESKCOM_SUBDOMAIN           # Required (<subdomain>.desk.com)
  consumer_key        DESKCOM_CONSUMER_KEY        # Required
  consumer_secret     DESKCOM_CONSUMER_SECRET     # Required
  oauth_token         DESKCOM_OAUTH_TOKEN         # Required
  oauth_token_secret  DESKCOM_OAUTH_TOKEN_SECRET  # Required
  store_file          /var/log/replies.yml        # Optional (filepath)
  output_format       simple                      # Optional (simple(default))
  input_api           replies                     # Optional (cases(default) or replies)
  tag                 deskcom.replies             # Required
  time_column         created_at
</source>

<match **>
  type tdlog
  apikey TREASUREDATA_API_KEY

  auto_create_table
  buffer_path /var/log/td-agent/tdlog
</match>
```

Please check store_file's permission to write by fluentd.

## TO DO

- Allows over 2 input_api (Ex. input_api cases,replies)
- Add other input_api
- Add Rate Limits
- Add feature to remind last collect cases or replies when forced termination.

## Copyright

Copyright (c) 2014 Toru Takahashi

## License

MIT License

