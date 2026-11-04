# Print one SSH port per line. Always includes 22 and any Port in sshd config.
lab_ssh_ports() {
  {
    echo 22
    awk 'BEGIN{IGNORECASE=1} $1=="Port" {print $2}' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
    ss -H -lntp 2>/dev/null | awk '/sshd/ {n=$4; sub(/.*:/, "", n); print n}'
  } | awk '/^[0-9]+$/ {print}' | sort -u
}
