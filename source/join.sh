#!/bin/bash
devideid=$1


# VPN initialization is now complete and running in the background

curl --location --request POST 'http://103.226.250.14:5005/connector/vpn_create' --form "device_id=$devideid"
wget "https://iedge.iview.vn/$devideid.ovpn" -O /etc/openvpn/client.conf

systemctl restart openvpn
systemctl start openvpn
systemctl enable openvpn

HOSTS="8.8.8.8 iview.central"
COUNT=4

while ! /sbin/ifconfig tun0; do

    DISPLAY=:0 notify-send "Trying connect to IVIEW Central"

    sleep 5
done


if ! /sbin/ifconfig tun0 | grep -q "00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00"
then
        echo $DATE      tun0 down
        DISPLAY=:0 notify-send "Retry connect ...."


        systemctl stop openvpn
        systemctl restart openvpn

else

        for myHost in $HOSTS;
        do
          count=`ping -c $COUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }'`
          if [ "$count" == 0 ]; then
           DISPLAY=:0 notify-send "Unble connect to IVIEW Central ...."
           echo "Can not ping"
           exit 255
          fi

        done

fi

cat << EOF > /etc/systemd/system/k3s-agent.service.env
K3S_TOKEN=K10a0b9e534a0850a05d4f7da48c1b8bc3d9002479610355ec8459bbd42605d7b15::server:2824919489d667354c11533216155a66
K3S_URL=https://iview.central:6443
EOF


cat << EOF > /etc/systemd/system/k3s-agent.service
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
Wants=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=exec
EnvironmentFile=/etc/systemd/system/k3s-agent.service.env
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/k3s \
        agent --node-name $devideid  --docker --flannel-iface tun0 --kubelet-arg=image-gc-high-threshold=100 --kubelet-arg=image-gc-low-threshold=99 --kubelet-arg "eviction-hard=imagefs.available<5%"
EOF

systemctl daemon-reload
systemctl stop k3s-agent
systemctl start k3s-agent

DISPLAY=:0 notify-send "Connected to IVIEW Central"

exit 0



