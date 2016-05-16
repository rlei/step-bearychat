# step-bearychat

A BearyChat notifier written in `bash` and `curl`. Make sure you create a BearyChat
webhook first.

This repo is based on Wercker's official [Slack notifier](https://github.com/wercker/step-slack).

# Options

- `url` The BearyChat webhook url
- `channel` (optional) The BearyChat channel (excluding `#`)
- `notify_on` (optional) If set to `failed`, it will only notify on failed
builds or deploys.
- `branch` (optional) If set, it will only notify on the given branch


# Example

```yaml
build:
    after-steps:
        - bearychat-notifier:
            url: $BEARYCHAT_URL
            channel: notifications
            branch: master
```

The `url` parameter is the BearyChat webhook that wercker should post to.
You can create an *incoming webhook* on your BearyChat channel page.
This url is then exposed as an environment variable (in this case
`$BEARYCHAT_URL`) that you create through the wercker web interface as *deploy pipeline variable*.

# License

The MIT License (MIT)

# Changelog (of the original step-slack)

## 1.2.0

- added `branch` option

## 1.1.0

- `channel` is now optional (wercker/step-slack#5)

## 1.0.0

- Initial release
