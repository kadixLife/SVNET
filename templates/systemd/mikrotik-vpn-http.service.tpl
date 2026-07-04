[Unit]
Description=MikroTik VPN temporary config HTTP serve
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server {{HTTP_PORT}} --bind 0.0.0.0 --directory {{OUTPUT_DIR}}
Restart=no

[Install]
WantedBy=multi-user.target
