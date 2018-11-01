{% from slspath + "/map.jinja" import vault with context -%}

include:
  - vault

{% if not vault.dev_mode %}
/etc/vault/config:
  file.directory:
    - makedirs: true
    - user: root
    - group: root
    - mode: 755

/etc/vault/config/server.hcl:
  file.managed:
    - source: salt://{{ slspath }}/files/server.hcl.jinja
    - template: jinja
    - context:
      vault:
        {{ vault | yaml }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/vault/config
    - watch_in:
      - service: vault

vault_set_cap_mlock:
  cmd.run:
    - name: setcap cap_ipc_lock=+ep $(readlink -f /usr/local/bin/vault)
    - onchanges:
      - /usr/local/bin/vault

{%   if vault.self_signed_cert.enabled -%}
openssl:
  pkg.installed

generate self signed SSL certs:
  cmd.script:
    - source: salt://{{ slspath }}/files/cert-gen.sh.jinja
    - template: jinja
    - context:
      vault:
        {{ vault | yaml }}
    - args: {{ vault.self_signed_cert.hostname }} {{ vault.self_signed_cert.password }}
    - cwd: /etc/vault
    - creates: /etc/vault/{{ vault.self_signed_cert.hostname }}.pem
    - require:
      - openssl
      - /etc/vault/config
    - require_in:
      - service: vault
{%   endif %}
{%- endif %}

{%- if grains.init == 'systemd' %}
/etc/systemd/system/vault.service:
  file.managed:
    - source: salt://{{ slspath }}/files/vault_systemd.service.jinja
    - template: jinja
    - context:
      vault:
        {{ vault | yaml }}
    - user: root
    - group: root
    - mode: 644
    - order: 1
    - watch_in:
      - service: vault
  cmd.run:
    - name: systemctl daemon-reload
    - order: 1
    - onchanges:
      - file: /etc/systemd/system/vault.service

{% elif grains.init == 'upstart' %}
/etc/init/vault.conf:
  file.managed:
    - source: salt://{{ slspath }}/files/vault_upstart.conf.jinja
    - template: jinja
    - context:
      vault:
        {{ vault | yaml }}
    - user: root
    - group: root
    - mode: 644
    - order: 1
    - watch_in:
      - service: vault
  cmd.run:
    - name: initctl reload-configuration
    - order: 1
    - onchanges:
      - file: /etc/init/vault.conf
{% endif -%}

vault:
  service.running:
    - enable: true
    - watch:
      - /usr/local/bin/vault
