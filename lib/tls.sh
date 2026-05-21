#!/usr/bin/env bash
# lib/tls.sh — domain validation and Caddyfile rendering.
# Sourced, not executed.

# validate_domain <domain> <expected_ip>
# Checks that <domain> resolves to <expected_ip>.
# Returns 0 if match, 1 if mismatch, 2 if no A record.
validate_domain() {
  local domain="$1" expected="$2"
  local resolved
  resolved=$(dig +short A "${domain}" | head -n1)
  if [[ -z "${resolved}" ]]; then
    echo "domain ${domain} has no DNS A record" >&2
    return 2
  fi
  if [[ "${resolved}" != "${expected}" ]]; then
    echo "domain ${domain} does not resolve to ${expected} (got: ${resolved})" >&2
    return 1
  fi
  return 0
}

# public_ip
# Echoes the VPS's public IPv4 address.
public_ip() {
  curl -fsS --max-time 5 https://api.ipify.org \
    || curl -fsS --max-time 5 https://ifconfig.me \
    || { echo "could not determine public IP" >&2; return 1; }
}

# caddy_render <out_file> <domain> <acme_email> <upstream_host:port>
# Writes a Caddyfile that reverse-proxies <domain> to <upstream>, with
# automatic Let's Encrypt cert issuance.
caddy_render() {
  local out="$1" domain="$2" email="$3" upstream="$4"
  cat > "${out}" <<EOF
{
  email ${email}
}

${domain} {
  encode zstd gzip
  reverse_proxy ${upstream}
}
EOF
}
