*This project has been created as part of the 42 curriculum by mandrini.*

---
<div align="center">

# Born2beRoot

</div>

> A system administration project from the 42 curriculum - setting up a secure Linux server from scratch inside a virtual machine, with strict rules around partitioning, user management, security policies, and monitoring.


<br>

<div align="center">

![42 School](https://img.shields.io/badge/42-School-000000?style=flat-square&logo=42&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-13-A81D33?style=flat-square&logo=debian&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-7.0-183A61?style=flat-square&logo=virtualbox&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=flat-square)

</div>


## Description

Born2beRoot is an introduction to **system administration** and **virtualization**. The goal is to create and configure a Linux virtual machine that behaves like a real server, applying strict security rules from the ground up.

There is no graphical interface - everything is done through the command line. By the end of the project, you will have:

- A running virtual machine with an encrypted disk (LVM).
- A configured SSH server accessible only on port 4242.
- A firewall (UFW) that blocks all ports except 4242.
- A strong password policy enforced system-wide.
- A configured `sudo` with logging and restrictions.
- A monitoring script (`monitoring.sh`) that broadcasts system information every 10 minutes.

The only file submitted to the Git repository is a `signature.txt` file containing the SHA1 hash of the virtual machine's disk, and a `README.md`.

---

## Project Design Choices

### Why Debian?

**Debian** was chosen as the operating system for this project. Here is why, along with an honest look at its strengths and weaknesses.

#### Advantages of Debian

- **Stability** : Debian's stable branch is thoroughly tested before release. Packages are older but very reliable, which is exactly what you want on a server.
- **Beginner-friendly for sysadmin** : The documentation is extensive, the community is large, and most beginner guides target Debian or Ubuntu (which is based on Debian).
- **APT package manager** : Installing, updating, and removing software is simple and well-documented.
- **AppArmor included** : AppArmor is the Mandatory Access Control system used on Debian. It is easier to configure and understand than SELinux, making it a better fit for a first server setup.
- **No mandatory complexity** : Unlike Rocky Linux, Debian does not require setting up SELinux with its complex policy rules, nor KDump.

#### Disadvantages of Debian

- **Older packages** : Because stability is prioritized, packages in Debian stable can be significantly behind the latest versions. This can be a problem if you need cutting-edge software.
- **Not enterprise-standard** : In professional environments, Red Hat-based distributions (like Rocky or RHEL) are often the standard. Learning Debian does not directly translate to working with enterprise Linux systems.
- **Less SELinux exposure** : Debian uses AppArmor by default, not SELinux. Many enterprise environments use SELinux, so you may need to learn it separately later.

---

### Partitioning

The disk is partitioned using **LVM (Logical Volume Manager)** with encryption. The partition setup looks like this:

```
sda
├── sda1         → /boot        (unencrypted, contains bootloader files)
├── sda2         → (1K, empty extended partition)
└── sda5         → encrypted with LUKS
    └── sda5_crypt (LVM physical volume)
        ├── LVMGroup-root     → /          (the main system)
        ├── LVMGroup-swap     → [SWAP]     (virtual memory)
        └── LVMGroup-home     → /home      (user files)
```

**Why LVM?** LVM allows you to resize partitions easily without repartitioning the physical disk. It also supports volume groups that span multiple physical drives.

**Why encryption?** Encrypting the partition means that even if someone physically steals the disk, they cannot read the data without the passphrase. This is enforced using LUKS (Linux Unified Key Setup).

---

### Security Policies

#### Password Policy (configured in `/etc/login.defs` and via `libpam-pwquality`)

| Rule | Value |
|------|-------|
| Password expiry | Every 30 days |
| Minimum days before change | 2 days |
| Warning before expiry | 7 days |
| Minimum length | 10 characters |
| Must contain | 1 uppercase, 1 lowercase, 1 digit |
| Max consecutive identical chars | 3 |
| Cannot contain username | Yes |
| At least 7 new characters vs previous | Yes (non-root only) |

#### Sudo Policy (configured in `/etc/sudoers.d/`)

| Rule | Value |
|------|-------|
| Max wrong password attempts | 3 |
| Custom error message | Yes (defined freely) |
| Log all sudo commands | Yes - `/var/log/sudo/` |
| TTY mode required | Yes |
| Allowed binary paths | Restricted to standard system paths |

---

### User Management

- The `root` account exists but **cannot log in via SSH**.
- A non-root user named `mandrini` is created.
- This user belongs to two groups: `user42` and `sudo`.
- The `sudo` group gives the user the ability to run commands as root, subject to the sudo policy above.

---

### Services Installed

| Service | Purpose |
|---------|---------|
| OpenSSH server | Allows remote connection via SSH on port 4242 |
| UFW | Firewall - only port 4242 is open |
| AppArmor | Mandatory Access Control - limits what programs can do |
| cron | Schedules the monitoring script to run every 10 minutes |

---

## Comparisons

### Debian vs Rocky Linux

| Feature | Debian | Rocky Linux |
|---------|--------|-------------|
| Base | Independent | Based on RHEL (Red Hat Enterprise Linux) |
| Package manager | APT (`apt`, `apt-get`) | DNF / YUM |
| Security module | AppArmor (default) | SELinux (mandatory) |
| Firewall tool | UFW | firewalld |
| Difficulty for beginners | Lower | Higher |
| Enterprise use | Common in web hosting | Standard in enterprise/corporate environments |
| Stability | Very stable (slow updates) | Very stable (RHEL-aligned) |
| Setup complexity for this project | Lower | Higher (SELinux policies, no KDump required but SELinux config is complex) |

**Summary:** Debian is the better choice for learning the basics of system administration. Rocky Linux is closer to what you would use in a real company, but requires more configuration knowledge upfront.

---

### AppArmor vs SELinux

Both are **Mandatory Access Control (MAC)** systems. They restrict what programs are allowed to do on the system, even if the program is compromised.

| Feature | AppArmor | SELinux |
|---------|----------|---------|
| Used by default on | Debian, Ubuntu | Rocky, Fedora, RHEL |
| Configuration style | Profile-based (per application) | Label-based (every file and process gets a label) |
| Ease of use | Easier - profiles are readable text files | Harder - requires understanding of policies and labels |
| Flexibility | Less flexible | Very flexible and powerful |
| Verification command | `aa-status` | `sestatus` |
| If something breaks | Easier to debug | Harder to debug |

**Summary:** AppArmor is more approachable for beginners. SELinux is more powerful and granular, but significantly harder to configure and troubleshoot. Both achieve the same fundamental goal: limiting what a process can access.

---

### UFW vs firewalld

Both are tools for managing firewall rules on Linux. They are front-ends for the underlying `iptables` / `nftables` system.

| Feature | UFW (Uncomplicated Firewall) | firewalld |
|---------|------------------------------|-----------|
| Used by default on | Debian, Ubuntu | Rocky, Fedora, RHEL |
| Ease of use | Very simple - commands are readable and intuitive | More complex - uses zones and services |
| Configuration style | Command-line or simple rules files | Zone-based (each network interface belongs to a zone) |
| Dynamic rule changes | Requires reload | Supports live changes without dropping connections |
| Best for | Simple servers with basic needs | Complex network environments with multiple interfaces |
| Syntax example | `ufw allow 4242/tcp` | `firewall-cmd --add-port=4242/tcp --permanent` |

**Summary:** UFW is ideal for a simple server like this project. firewalld offers more flexibility for complex scenarios but comes with a steeper learning curve.

---

### VirtualBox vs UTM

Both are tools for creating and running **virtual machines** on your computer.

| Feature | VirtualBox | UTM |
|---------|------------|-----|
| Platform | Windows, Linux, macOS (Intel) | macOS (especially Apple Silicon M1/M2/M3) |
| License | Free and open-source (Oracle) | Free (open-source on GitHub) |
| Performance on Apple Silicon | Poor - no native ARM support | Excellent - runs natively on M1/M2/M3 chips |
| Performance on Intel machines | Very good | Not optimized for Intel |
| Interface | Mature, feature-rich GUI | Clean and simple GUI |
| Snapshot support | Yes | Yes |
| When to use | Any machine that is not Apple Silicon | Apple Silicon Macs only |
| Disk format | `.vdi` | `.qcow2` |

**Summary:** Use VirtualBox unless you are on an Apple Silicon Mac (M1/M2/M3), in which case use UTM. Both support all the features required for this project.

---

## Instructions

### 1. Prerequisites

- Download and install [VirtualBox](https://www.virtualbox.org/) (or [UTM](https://mac.getutm.app/) for Apple Silicon).
- Download the latest stable Debian ISO from [debian.org](https://www.debian.org/distrib/).

---

### 2. Creating the Virtual Machine

1. Open VirtualBox and click **New**.
2. Set the name (e.g., `Born2beRoot`), type to **Linux**, version to **Debian (64-bit)**.
3. Allocate at least **1024 MB RAM**.
4. Create a new virtual hard disk in **VDI format**, dynamically allocated, at least **8 GB**.
5. Start the VM and point it to the Debian ISO when prompted for a boot disk.

---

### 3. Installing Debian

During the Debian installer:

1. Choose **Install** (not graphical install).
2. Set language, location, and keyboard layout.
3. Set the hostname to `mandrini42`.
4. Leave domain name empty.
5. Set a strong root password.
6. Create a user named `mandrini` with a strong password.
7. When partitioning, choose **Manual** to set up LVM with encryption:
   - Create a primary partition for `/boot`.
   - Create an encrypted LVM partition for the rest of the disk.
   - Inside the LVM, create logical volumes for `/`, `[SWAP]`, and `/home`.
8. When asked about software to install, **deselect everything**.

---

### 4. Post-Installation Configuration

#### SSH on port 4242

```bash
sudo nano /etc/ssh/sshd_config
# Change: #Port 22 → Port 4242
# Change: PermitRootLogin prohibit-password → PermitRootLogin no
sudo systemctl restart ssh
```

#### UFW Firewall

```bash
sudo apt install ufw
sudo ufw allow 4242
sudo ufw enable
sudo ufw status
```

#### Password Policy

Install the password quality library:

```bash
sudo apt install libpam-pwquality
```

Edit `/etc/security/pwquality.conf`:

```
minlen = 10
ucredit = -1
lcredit = -1
dcredit = -1
maxrepeat = 3
usercheck = 1
difok = 7
enforce_for_root
```

Edit `/etc/login.defs`:

```
PASS_MAX_DAYS   30
PASS_MIN_DAYS   2
PASS_WARN_AGE   7
```

#### Sudo Configuration

Create a file `/etc/sudoers.d/born2beroot`:

```
Defaults        passwd_tries=3
Defaults        badpass_message="Wrong password. Please try again."
Defaults        logfile="/var/log/sudo/sudo.log"
Defaults        log_input,log_output
Defaults        requiretty
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
```

Create the log directory:

```bash
sudo mkdir -p /var/log/sudo
```

#### User Groups

```bash
sudo groupadd user42
sudo usermod -aG user42 mandrini
sudo usermod -aG sudo mandrini
```

Verify:

```bash
groups mandrini
# Should show: mandrini sudo user42
```

#### monitoring.sh

Create `/usr/local/bin/monitoring.sh` and make it executable:

```bash
chmod +x /usr/local/bin/monitoring.sh
```

Schedule it with cron to run every 10 minutes:


---

### 5. Generating the signature.txt

Once your virtual machine is fully configured and **turned off**, generate the SHA1 hash of its disk file.

Find your disk file:

**Linux:** `~/goinfre/Born2beRoot/Born2beRoot.vdi`

Run the following command:

```bash
sha1sum ~/goinfre/Born2beRoot/Born2beRoot.vdi > signature.txt
```


> **Important:** Every time you start the virtual machine, the signature changes. Do not start your VM after generating the signature, or regenerate it just before submitting.

---

## Resources

### Official Documentation

- [Debian Official Documentation](https://www.debian.org/doc/) - Installation guides, manuals, and reference.
- [Debian Administrator's Handbook](https://debian-handbook.info/browse/stable/) - A complete, free book on Debian system administration.
- [OpenSSH Manual](https://www.openssh.com/manual.html) - Official reference for SSH configuration.
- [UFW Documentation](https://help.ubuntu.com/community/UFW) - How to configure UFW.
- [AppArmor Documentation](https://gitlab.com/apparmor/apparmor/-/wikis/home) - Official AppArmor wiki.
- [PAM (Pluggable Authentication Modules)](https://www.linux-pam.org/Linux-PAM-html/) - How password policies are enforced.
- [sudoers manual](https://www.sudo.ws/docs/man/sudoers.man/) - Official sudo configuration reference.
- [cron manual](https://man7.org/linux/man-pages/man5/crontab.5.html) - How to schedule tasks with cron.

### Useful Articles

- [Debian vs Rocky Linux - What's the difference?](https://www.fosslinux.com/49448/debian-vs-rocky-linux.htm)
- [AppArmor vs SELinux](https://www.baeldung.com/linux/apparmor-vs-selinux) - Clear comparison of both MAC systems.
- [UFW vs firewalld](https://www.tecmint.com/ufw-vs-firewalld/) - Side-by-side comparison.
- [Understanding LVM](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations) - DigitalOcean's clear introduction.

### How AI Was Used

- **Understanding concepts** - Asking for plain-language explanations of concepts like LVM, LUKS, AppArmor, and sudo policies before diving into the official documentation.
- **Debugging assistance** - Helping interpret error messages encountered during configuration.

AI was **not** used to directly configure the virtual machine. Every configuration was applied manually and understood before submission.
