# -*- coding: utf-8 -*-
# vim: ft=sls syntax=yaml softtabstop=2 tabstop=2 shiftwidth=2 expandtab autoindent

{% from "vault/map.jinja" import vault with context -%}

{%- if vault["config"]["hcl_format"] %}
vault-config-config-file:
  file.managed:
    - name: /etc/vault/conf.d/config.hcl
    - encoding: utf-8
    - user: root
    - group: vault
    - mode: 0440
    - template: jinja
    - source: salt://{{ slspath }}/config.hcl.j2
    - context:
      vault: {{ vault | json }}

vault-config-config-clean:
  file.absent:
    - name: /etc/vault/conf.d/config.json
{%- else %}
vault-config-config-file:
  file.serialize:
    - name: /etc/vault/conf.d/config.json
    - encoding: utf-8
    - formatter: json
    - dataset: {{ vault.config | json }}
    - user: root
    - group: vault
    - mode: 0640

vault-config-config-clean:
  file.absent:
    - name: /etc/vault/conf.d/config.hcl
{%- endif %}

vault-config-systemd-env:
  file.managed:
    - name: /etc/vault/vault-systemd.env
    - encoding: utf-8
    - user: vault
    - group: vault
    - mode: 0440
    - template: jinja
    - source: salt://{{ slspath }}/vault-systemd.env.j2
    - context:
      vault: {{ vault | json }}

vault-config-local-env:
  file.managed:
    - name: /etc/vault/local.env
    - encoding: utf-8
    - user: vault
    - group: vault
    - mode: 0444
    - template: jinja
    - source: salt://{{ slspath }}/env.sh.j2
    - context:
      vault: {{ vault | json }}
      hostname: {{ vault["config"]["hostname"] }}
