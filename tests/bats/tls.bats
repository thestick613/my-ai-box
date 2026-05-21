#!/usr/bin/env bats

load test_helper

setup() {
  load_lib tls
  setup_tmp
  mkdir -p "${TEST_TMP}/bin"
  export PATH="${TEST_TMP}/bin:${PATH}"
}

@test "validate_domain: succeeds when dig returns the expected IP" {
  cat > "${TEST_TMP}/bin/dig" <<EOF
#!/usr/bin/env bash
echo "203.0.113.5"
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_success
}

@test "validate_domain: fails when dig returns a different IP, with helpful message" {
  cat > "${TEST_TMP}/bin/dig" <<EOF
#!/usr/bin/env bash
echo "198.51.100.99"
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_failure
  assert_output --partial "does not resolve to"
  assert_output --partial "203.0.113.5"
}

@test "validate_domain: fails on empty dig output" {
  cat > "${TEST_TMP}/bin/dig" <<EOF
#!/usr/bin/env bash
echo ""
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_failure
  assert_output --partial "no DNS A record"
}
