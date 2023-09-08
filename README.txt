export VAULT_CACERT=/var/lib/vault/tls/vault-ca.pem
export VAULT_ADDR=https://server.fqdn:8200/

vault status
vault operator init -key-shares=1 -key-threshold=1
