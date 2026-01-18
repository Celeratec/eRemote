# eRemote

**A custom deployment of RustDesk by [Celeratec](https://celeratec.com)**

<p align="center">
  <img src="res/logo-header.svg" alt="eRemote - Remote Desktop Solution"><br>
  <a href="#building-from-source">Build</a> •
  <a href="#docker-build">Docker</a> •
  <a href="#file-structure">Structure</a>
</p>

eRemote is Celeratec's branded remote desktop client, built on the open-source [RustDesk](https://github.com/rustdesk/rustdesk). It provides secure, private remote access for managed service providers (MSPs) and enterprises.

## What is eRemote?

eRemote is a complete remote desktop solution offering:

- **Full remote control** – Access desktops, transfer files, and manage endpoints
- **Self-hosted infrastructure** – Connect to your own [eRemote Server](https://github.com/Celeratec/eremote-server)
- **Cross-platform** – Windows, macOS, Linux, Android, iOS
- **Secure by design** – End-to-end encryption with no third-party relay dependencies
- **MSP-ready** – Designed for managing multiple client environments

## Features

| Feature | Description |
|---------|-------------|
| Remote Desktop | Full remote control with multi-monitor support |
| File Transfer | Drag-and-drop file transfer between machines |
| Clipboard Sync | Seamless clipboard sharing |
| Audio Support | Remote audio streaming |
| Unattended Access | Service mode for always-on access |
| TCP Tunneling | Port forwarding through secure tunnels |
| Wake-on-LAN | Wake sleeping machines remotely |
| 2FA | Two-factor authentication support |

## Quick Start

### For End Users

1. Download the eRemote client for your platform
2. Configure with your eRemote Server details:
   - **ID Server**: `your-server:21116`
   - **Relay Server**: `your-server:21117`
   - **Key**: Your server's public key
3. Share your ID with the technician or connect to managed endpoints

### For MSPs

See the [eRemote Server repository](https://github.com/Celeratec/eremote-server) for server deployment instructions.

## Building from Source

### Prerequisites

- Rust toolchain (latest stable)
- [vcpkg](https://github.com/microsoft/vcpkg) with dependencies
- Flutter SDK (for Flutter builds)

### Install vcpkg Dependencies

```bash
# Windows
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static

# Linux/macOS
vcpkg install libvpx libyuv opus aom
```

### Build Commands

```bash
# Clone the repository
git clone --recurse-submodules https://github.com/Celeratec/eRemote.git
cd eRemote

# Desktop (Sciter UI - simpler)
cargo build --release

# Desktop (Flutter UI - recommended)
python3 build.py --flutter --release

# Android
cd flutter
flutter build apk --release

# iOS
cd flutter
flutter build ios --release
```

## Docker Build

```bash
git clone https://github.com/Celeratec/eRemote.git
cd eRemote
git submodule update --init --recursive
docker build -t "eremote-builder" .

# Build the application
docker run --rm -it -v $PWD:/home/user/rustdesk \
  -v eremote-git-cache:/home/user/.cargo/git \
  -v eremote-registry-cache:/home/user/.cargo/registry \
  -e PUID="$(id -u)" -e PGID="$(id -g)" eremote-builder
```

## File Structure

| Directory | Description |
|-----------|-------------|
| `libs/hbb_common` | Video codec, config, TCP/UDP wrapper, protobuf, file transfer |
| `libs/scrap` | Screen capture |
| `libs/enigo` | Platform-specific keyboard/mouse control |
| `libs/clipboard` | File copy/paste for Windows, Linux, macOS |
| `src/server` | Audio/clipboard/input/video services, network connections |
| `src/client.rs` | Peer connection handling |
| `src/rendezvous_mediator.rs` | Communication with eRemote Server |
| `src/platform` | Platform-specific code |
| `flutter` | Flutter code for desktop and mobile |

## Based on RustDesk

eRemote is built on [RustDesk](https://github.com/rustdesk/rustdesk), an open-source remote desktop solution written in Rust. We maintain this fork to:

- Provide Celeratec branding and customization
- Pre-configure connections to eRemote Server infrastructure
- Offer MSP-specific features and integrations

For the upstream project, visit [rustdesk.com](https://rustdesk.com).

## Related Projects

- [eRemote Server](https://github.com/Celeratec/eremote-server) – Self-hosted ID/relay server
- [RustDesk](https://github.com/rustdesk/rustdesk) – Upstream open-source project
- [RustDesk Server](https://github.com/rustdesk/rustdesk-server) – Upstream server project

## License

This project is licensed under the same terms as RustDesk. See [LICENCE](LICENCE) for details.

---

**Maintained by [Celeratec](https://celeratec.com)** – IT Solutions for Modern Businesses
