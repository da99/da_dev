
Links:
======

* Entre: Alternative to inotify. Reload servers and browers
  on file changes: http://entrproject.org


Reference & Intro:
==================

```zsh
  da_dev compile file.name.ext

  da_dev watch

  da_dev watch run # defaults to: da_dev specs compile run
  da_dev watch run reload
  da_dev watch run my_cmd with -args
  da_dev watch run __ with -args

  da_dev watch run-once reload
  da_dev watch run-once my_cmd with -args
  da_dev watch run-once __ with -args
```
