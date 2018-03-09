
Links:
======

* Entre: Alternative to inotify. Reload servers and browers
  on file changes: http://entrproject.org


Reference & Intro:
==================

```zsh
  da_dev compile file.name.ext

  da_dev watch
  da_dev watch reload

  da_dev watch run-file myfile.1.txt
  da_dev watch run-file myfile.2.txt

  da_dev watch proc sleep 10

  da_dev watch run-last-file

  da_dev watch run my_cmd with -args
  da_dev watch run __ with -args
```

For `watch` files:

```zsh
  reset
  clear
  bin compile
  run my process
  proc my long running process
  # bin compile
  PING
```
