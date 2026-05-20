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

@test "require_root: succeeds when id -u returns 0" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/id" <<EOF
#!/usr/bin/env bash
echo "0"
EOF
  chmod +x "${TEST_TMP}/bin/id"
  export PATH="${TEST_TMP}/bin:${PATH}"
  run require_root
  assert_success
}

@test "require_root: fails with a helpful message when id -u returns non-zero" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/id" <<EOF
#!/usr/bin/env bash
echo "1000"
EOF
  chmod +x "${TEST_TMP}/bin/id"
  export PATH="${TEST_TMP}/bin:${PATH}"
  run require_root
  assert_failure
  assert_output --partial "must be run as root"
}

@test "install_pkg: invokes apt-get install -y with the given packages" {
  # Mock apt-get by putting a fake on PATH.
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/apt-get" <<EOF
#!/usr/bin/env bash
echo "apt-get called with: \$*" >> "${TEST_TMP}/apt-get.log"
EOF
  chmod +x "${TEST_TMP}/bin/apt-get"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run install_pkg curl jq
  assert_success
  run cat "${TEST_TMP}/apt-get.log"
  assert_output --partial "update"
  assert_output --partial "install -y curl jq"
}

@test "install_docker: is a no-op when docker is already on PATH" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/docker" <<EOF
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_TMP}/bin/docker"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run install_docker
  assert_success
  assert_output --partial "docker already installed"
}

@test "install_docker: downloads and runs get.docker.com when docker is missing" {
  # Force docker missing by overriding PATH to exclude any real docker.
  export PATH="${TEST_TMP}/bin:/usr/bin:/bin"
  # Mock curl + sh so we record the URL it was asked to fetch.
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/curl" <<EOF
#!/usr/bin/env bash
echo "curl called: \$*" >> "${TEST_TMP}/curl.log"
echo "echo 'fake install script'"
EOF
  chmod +x "${TEST_TMP}/bin/curl"
  cat > "${TEST_TMP}/bin/sh" <<EOF
#!/usr/bin/env bash
echo "sh called" >> "${TEST_TMP}/sh.log"
exit 0
EOF
  chmod +x "${TEST_TMP}/bin/sh"

  run install_docker
  assert_success
  run cat "${TEST_TMP}/curl.log"
  assert_output --partial "get.docker.com"
}
