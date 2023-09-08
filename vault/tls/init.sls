{%- from "vault/map.jinja" import vault with context -%}

{%- if vault["tls"]["ca_content"] %}
/var/lib/vault/tls/vault-ca.pem:
  file.managed:
    - user: vault
    - group: root
    - mode: 0444
    - contents_pillar: vault:tls:ca_content
{%- endif %}

{%- if vault["tls"]["priv_content"] %}
/var/lib/vault/tls/vault-key.pem:
  file.managed:
    - user: vault
    - group: root
    - mode: 0400
    - contents_pillar: vault:tls:priv_content
{%- endif %}

{%- if vault["tls"]["cert_content"] %}
/var/lib/vault/tls/vault-cert.pem:
  file.managed:
    - user: vault
    - group: root
    - mode: 0400
    - contents_pillar: vault:tls:cert_content
{%- endif %}

# vim: ft=sls syntax=yaml softtabstop=2 tabstop=2 shiftwidth=2 expandtab autoindent
