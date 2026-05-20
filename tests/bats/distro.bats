#!/usr/bin/env bats

load test_helper

setup() {
  load_lib distro
  setup_tmp
  # Fake /etc/os-release for these tests.
  FAKE_OS_RELEASE="${TEST_TMP}/os-release"
  export FAKE_OS_RELEASE
}

@test "detect_distro: Ubuntu 24.04 returns 'ubuntu-24.04'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=ubuntu
VERSION_ID="24.04"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "ubuntu-24.04"
}

@test "detect_distro: Ubuntu 22.04 returns 'ubuntu-22.04'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=ubuntu
VERSION_ID="22.04"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "ubuntu-22.04"
}

@test "detect_distro: Debian 12 returns 'debian-12'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=debian
VERSION_ID="12"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "debian-12"
}

@test "detect_distro: unsupported distro returns non-zero with message on stderr" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=arch
VERSION_ID="rolling"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_failure
  assert_output --partial "unsupported distro"
}

@test "detect_distro: missing os-release returns non-zero" {
  run detect_distro "${TEST_TMP}/does-not-exist"
  assert_failure
  assert_output --partial "cannot detect distro"
}
