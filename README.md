<h1 align="center">🔒 Kali Linux Autoconfig 🔧</h1>
<p align="center">
    <em>A script to automate the configuration and hardening of a fresh Kali Linux installation on a VMware virtual machine.</em>
</p>

---

## 🌟 Features

- 🧰 Installs essential tools and packages such as Git, nano, Zsh, open-vm-tools-desktop, fuse, and rkhunter.
- 💻 Configures Powerlevel10k prompt with Oh My Zsh.
- 🛡️ Sets up Rkhunter and Samhain for security scans and creates cron jobs for daily security scans.
- 🚀 Implements basic security hardening measures, including disabling SSH root access and removing the OpenSSH server package.
- 🔐 Implements advanced security hardening measures:
  - Disabling unused filesystems and network protocols.
  - Restricting core dumps.
  - Configuring auditd for system auditing.
  - Secure user account settings.
  - Configuring log monitoring with Logwatch.
  - Installing and configuring Tripwire for file integrity monitoring.
  - Installing and running Lynis for system hardening and vulnerability assessments.
- 💡 Provides an easy-to-use script with a progress spinner and clear output messages.

## 📋 Prerequisites

- A fresh Kali Linux installation on a VMware virtual machine.
- Root access to the virtual machine.

## 🚀 Usage

1. Clone this repository to your Kali Linux VM:

   ```
   git clone https://github.com/yourusername/kali-linux-autoconfig-vmware.git
   ```

2. Change to the `scripts` directory:

   ```
   cd kali-linux-autoconfig-vmware/scripts
   ```

3. Make the script executable:

   ```
   chmod +x autokali.sh
   ```

4. Run the script as root with bash:

   ```
   sudo bash autokali.bash
   ```

5. Follow the prompts and let the script complete the configuration and hardening process.

## 🔧 Customization

Feel free to modify the script according to your needs. You can add or remove packages, adjust hardening settings, or implement additional security measures as required.

## 📚 License

This project is open-source and available under the [MIT License](LICENSE).

---

<p align="center">
  <em>Enjoy a more secure Kali Linux experience! 🎉</em>
</p>
