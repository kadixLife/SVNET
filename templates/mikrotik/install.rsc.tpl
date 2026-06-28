# СвободаNET MikroTik install/update template
# Rendered by svnet. Works only with SVNET-marked objects.

:local svnetBase "http://{{SERVER_IP}}:{{HTTP_PORT}}"
:local svnetOvpnFile "mikrotik.ovpn"

:if ([:len [/interface ovpn-client find name="{{MIKROTIK_OVPN_IF}}"]] = 0) do={
    :log warning "SVNET: OpenVPN client not found, fetching mikrotik.ovpn"
    :do { /tool fetch url=($svnetBase . "/clients/mikrotik.ovpn") dst-path=$svnetOvpnFile keep-result=yes } on-error={ :log warning "SVNET: cannot fetch mikrotik.ovpn" }
    :do { /interface ovpn-client import-ovpn-configuration ovpn-configuration=$svnetOvpnFile ovpn-user=ovpnuser skip-cert-import=no } on-error={ :log warning "SVNET: automatic OpenVPN import failed, import mikrotik.ovpn manually" }
}

:if ([:len [/interface ovpn-client find name="{{MIKROTIK_OVPN_IF}}"]] = 0) do={
    :error "SVNET: OpenVPN interface {{MIKROTIK_OVPN_IF}} is missing"
}

:log warning "SVNET: use generated svnet-mikrotik-install.rsc from HTTP publish for full rules"
