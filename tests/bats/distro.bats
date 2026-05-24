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

@test "detect_cpu_count: returns nproc output when available" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "4"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"
  export PATH="${TEST_TMP}/bin:${PATH}"
  run detect_cpu_count
  assert_success
  assert_output "4"
}

@test "detect_cpu_count: falls back to /proc/cpuinfo if nproc missing" {
  # Hide nproc by setting PATH to nothing useful
  export PATH="${TEST_TMP}/empty:/usr/bin:/bin"
  mkdir -p "${TEST_TMP}/empty"
  # Write a fake cpuinfo with 2 processors
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
processor	: 1
EOF
  run detect_cpu_count "${TEST_TMP}/cpuinfo"
  assert_success
  assert_output "2"
}

@test "detect_ram_gb: parses /proc/meminfo MemTotal" {
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        4194304 kB
MemFree:         1048576 kB
EOF
  run detect_ram_gb "${TEST_TMP}/meminfo"
  assert_success
  assert_output "4.0"
}

@test "detect_ram_gb: returns '?' when path missing" {
  run detect_ram_gb "${TEST_TMP}/does-not-exist"
  assert_output "?"
}

@test "detect_disk_free_gb: parses df output via mocked df" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
# Fake df output (header + one data row, sizes already in GB)
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 20 60 25% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  export PATH="${TEST_TMP}/bin:${PATH}"
  run detect_disk_free_gb "/some/path"
  assert_success
  assert_output "60"
}

@test "print_system_info: includes OS, CPU, RAM, Disk lines" {
  cat > "${TEST_TMP}/os-release" <<EOF
ID=ubuntu
VERSION_ID="24.04"
EOF
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        4194304 kB
EOF
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
processor	: 1
EOF
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 20 60 25% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  export PATH="${TEST_TMP}/bin:${PATH}"
  # Hide nproc to force /proc/cpuinfo fallback path
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "2"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"

  run print_system_info "/some/runtime" "${TEST_TMP}/os-release" "${TEST_TMP}/cpuinfo" "${TEST_TMP}/meminfo"
  assert_success
  assert_output --partial "OS:"
  assert_output --partial "ubuntu-24.04"
  assert_output --partial "CPU:"
  assert_output --partial "2 vCPU"
  assert_output --partial "RAM:"
  assert_output --partial "4.0 GB"
  assert_output --partial "Disk:"
  assert_output --partial "60 GB free"
}

@test "check_minimums: returns 0 + no warnings when above floors" {
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        4194304 kB
EOF
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
processor	: 1
EOF
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 20 60 25% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "2"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run check_minimums "/some/runtime" "${TEST_TMP}/cpuinfo" "${TEST_TMP}/meminfo"
  assert_success
  refute_output --partial "⚠"
}

@test "check_minimums: warns and returns non-zero when RAM is below 2 GB" {
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        1048576 kB
EOF
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
processor	: 1
EOF
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 20 60 25% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "2"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run check_minimums "/some/runtime" "${TEST_TMP}/cpuinfo" "${TEST_TMP}/meminfo"
  assert_failure
  assert_output --partial "RAM"
}

@test "check_minimums: warns when CPU < 2" {
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        4194304 kB
EOF
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
EOF
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 20 60 25% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "1"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run check_minimums "/some/runtime" "${TEST_TMP}/cpuinfo" "${TEST_TMP}/meminfo"
  assert_failure
  assert_output --partial "CPU"
}

@test "check_minimums: warns when disk free < 5 GB" {
  cat > "${TEST_TMP}/meminfo" <<EOF
MemTotal:        4194304 kB
EOF
  cat > "${TEST_TMP}/cpuinfo" <<EOF
processor	: 0
processor	: 1
EOF
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/df" <<EOF
#!/usr/bin/env bash
echo "Filesystem 1G-blocks Used Avail Use% Mounted on"
echo "/dev/sda1 80 78 2 98% /"
EOF
  chmod +x "${TEST_TMP}/bin/df"
  cat > "${TEST_TMP}/bin/nproc" <<EOF
#!/usr/bin/env bash
echo "2"
EOF
  chmod +x "${TEST_TMP}/bin/nproc"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run check_minimums "/some/runtime" "${TEST_TMP}/cpuinfo" "${TEST_TMP}/meminfo"
  assert_failure
  assert_output --partial "Disk"
}
