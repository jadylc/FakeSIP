# FakeSIP Docker Sidecar

把 FakeSIP 以 **sidecar 容器** 挂在 BT 客户端旁边，只伪装该容器的 **UDP** 流量
（DHT / UDP tracker announce）为 SIP VoIP 协议，宿主机与其他服务无感。

与 FakeHTTP 的关系：**互补而非替代**——FakeHTTP 处理 TCP（BT 数据传输），
FakeSIP 处理 UDP（peer 发现：DHT/UDP tracker）。两者可同时挂在同一容器
（默认队列号不同：fakehttp=512, fakesip=513；fwmark 不同 0x8000/0x10000）。

## 构建镜像

```bash
docker build -f docker/Dockerfile -t fakesip-sidecar:1.0 .
docker save fakesip-sidecar:1.0 | gzip > fakesip-sidecar.tar.gz
# 目标机导入
gunzip -c fakesip-sidecar.tar.gz | docker load
```

## 接入方式 A：compose

```yaml
  fakesip:
    image: fakesip-sidecar:1.0
    network_mode: "service:<BT服务名>"
    cap_add:
    - NET_ADMIN
    - NET_RAW
    security_opt:
    - seccomp:unconfined   # Docker 默认 seccomp 会拦 NFQUEUE netlink socket
    environment:
    - FAKESIP_TTL=4
    restart: always
```

## 接入方式 B：docker run（不重建主容器）

```bash
docker run -d --name fakesip-<名字> \
  --network container:<主容器名> \
  --restart unless-stopped \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  --security-opt seccomp=unconfined \
  fakesip-sidecar:1.0
```

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `FAKESIP_URI` | 随机 `sip:user@203.0.113.x` | SIP URI（一般不用设） |
| `FAKESIP_TTL` | `4` | 伪装包 TTL；sidecar 多一跳容器路由，出 eth0 后实际为 3 |
| `FAKESIP_EXTRA` | 空 | 附加参数，如 `-r 3`、`-1`（仅出站） |

## 验证

```bash
docker logs fakesip-<名字> | head        # 应看到 "listening on eth0..."
docker exec fakesip-<名字> nft list ruleset | grep -E "hook|to 513"
# 宿主机抓 SIP 伪装包（UDP 5060 端口特征）
tcpdump -i eth0 -nn -A "udp and ip[8:1]=3" | head -20
```

## 回滚

- compose：删掉 `fakesip` 块 → `up -d`；run 方式：`docker rm -f fakesip-<名字>`
- 容器停止时 netns 销毁，nft 规则自动消失，宿主机零残留。

## 常见坑

1. 默认 seccomp 拦 NFQUEUE，必须 `--security-opt seccomp=unconfined`
2. alpine `-dev` 包无静态库，镜像内用动态链接
3. 与 FakeHTTP sidecar 同挂一个容器时**兼容**（不同队列号/fwmark/nft 表名 fakehttp vs fakesip）
