

<a href="https://aimeos.org/">
    <img src="https://aimeos.org/fileadmin/template/icons/logo.png" alt="IVIEW logo" title="IVIEW Edge AI Solution" align="right" height="60" />
</a>

IVIEW Edge AI Solution
======================
[![Total Downloads](https://poser.pugx.org/aimeos/aimeos-typo3/d/total.svg)](https://packagist.org/packages/aimeos/aimeos-typo3)
[![Scrutinizer Code Quality](https://scrutinizer-ci.com/g/aimeos/aimeos-typo3/badges/quality-score.png?b=master)](https://scrutinizer-ci.com/g/aimeos/aimeos-typo3/?branch=master)
[![License](https://poser.pugx.org/aimeos/aimeos-typo3/license.svg)](https://packagist.org/packages/aimeos/aimeos-typo3)

:star: Star us on GitHub — it helps!

[iEdge](https://iview.vn) is the platform to manage and deploy AI application on ARM architect ( like Jetson .. )


## Table of content

- [Installation](#installation)

## Pre Installation

This document is for the latest iEdge **Beta 0.1 release and later**.

- Beta release: 0.1 ( 18/11/2020 )

- Requirements are required bellow:
		- SD Card: minimun 20
		- Hardware: [Jetson Nano 4GB RAM](https://developer.nvidia.com/embedded/jetson-nano-developer-kit), mouse, keyboard and monitor
		- OS: [Jetson Jetpack 4.3](https://developer.nvidia.com/jetpack-43-archive)
		- Software Manager: **Advanced Package Tool** (Linux) - APT with lastest update
		- Networking: internet access 
	
### Installation

Connect to Edge Device via SSH and run script bellow
```
wget https://github.com/Edge-IVIEW/iEdge/releases/download/0.1-beta.1/iview-install.sh
chmod +x iview-install.sh
./iview-install.sh

```

Please wait 15-20 minutes, depend your internet speed.

After install success please reboot your device and plug a monitor.

If have error please create and issue at Github Isssue


## Deploy Application Hub 

The page setup for AI Hub with iEdge 
* [20.10.x page tree]()
* [19.10.x page tree]()

**Note:** Currenly, we only support **attendance application**

### Register Device to the iVIEW.VN

* After reboot device, please wait until device open Register page in Monitor
	- **Step 1**: Fill the form with account and device's token that created from https://go.iview.vn 
![Go to the import view](https://i.imgur.com/z2vcGJH.png)

	- **Step 2**: 

## License

The iEdge Platform is licensed under the terms of the GPL Open Source
license and is available for free.

## Links

* [Web site]()
* [Documentation]()
* [Forum]()
* [Issue tracker]()
* [Source code]()

## Fly to Cloud

## END

