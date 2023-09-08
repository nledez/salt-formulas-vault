# -*- coding: utf-8 -*-
# vim: ft=sls syntax=yaml softtabstop=2 tabstop=2 shiftwidth=2 expandtab autoindent

{% from "vault/map.jinja" import vault with context -%}

/var/lib/vault/debug.yaml:
  file.serialize:
    - encoding: utf-8
    - formatter: yaml
    - user: root
    - group: vault
    - mode: 440
    - dataset: {{ vault.config | json }}
