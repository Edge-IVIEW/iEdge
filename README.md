





<a href="https://iview.vn/">
    <img src="https://i.imgur.com/EORKMiE.jpg" alt="IVIEW logo" title="IVIEW Edge AI Solution" align="right" height="60" />
</a>

IVIEW Edge AI Solution
======================


:star: Star us on GitHub — it helps!

[iEdge](https://iview.vn) is the platform to manage and deploy AI application on ARM architect ( like Jetson .. )

iEdge help manage Edge Device over internet.

[![iEdge demo](https://i.imgur.com/9N95HR0.png)](https://go.iview.vn/)
  

## Table of content

  

-  [Installation](#installation)


-  [Composer](#composer)

-  [Extension](#extension)

-  [Database](#database)

-  [Page setup](#page-setup)

-  [Upload the page tree file](#upload-the-page-tree-file)

-  [Go to the import view](#go-to-the-import-view)

-  [Import the page tree](#import-the-page-tree)

-  [SEO-friendly URLs](#seo-friendly-urls)

-  [License](#license)

-  [Links](#links)

  
## Create IVIEW Account

Go to https://go.iview.vn/ and login with your account.

Go to **System Management**, select **Manage BoxAI**

![](https://i.imgur.com/X3X3s6c.png)

Click **Create Token** and save token. Token will use  to register box.

![](https://i.imgur.com/1jigDUy.png)

## Pre Installation

This document is for the latest iEdge **Beta 0.1 release and later**.
- Beta release: 0.1 ( 18/11/2020 )
- Requirements are required bellow:
- SD Card: minimum 30 GB 
- Hardware: [Jetson Nano 4GB RAM](https://developer.nvidia.com/embedded/jetson-nano-developer-kit), mouse, keyboard and monitor
- Software Manager: **Advanced Package Tool** (Linux) - APT with lastest update
- Networking: Internet access with DHCP on first boot.


## Download ISO and Create bootable SD card

 
This document is for the latest iEdge AI **0.1 beta release and later**.
  - LTS release: 0.1 beta release

- Please download our ISO at: [link 01](https://iedge.s3-ap-southeast-1.amazonaws.com/jetson_nano_edge_ai.zip)
- After successfully downloaded, unzip to get file image and boot your SD card with [Rufus](https://rufus.ie/) or other tool.
![](https://i.imgur.com/TOy3OT1.png)

Wait 5-10 minutes to success and unplug SD device.
  
### Installation

- Insert micro SD card into Jetson Nano and boot. Please wait 2 minutes until Register form appear on monitor.
	- **STEP 1**: Fill Email, Password and Token that created into form and press **Next** to verify
![](https://i.imgur.com/dM5Uv2q.png)
	- **STEP 2**: Fill box name, box networking info, camera IP and press "Next" to process. If return error please check connect to camera IP or see back example bellow.![](https://i.imgur.com/UxZA4Dv.png)
	- **STEP 3**: Select Module to deploy. Currently, we only focus to **attendance** app. Please 5-10 minutes to sucessful and reboot your device. ![](https://i.imgur.com/4hHwoe7.png)
  


### Use

- Wait 3-5 minutes to open app afer reboot. During operation, please keep the internet connection for the device



### Composer
- All requirement be composed inside ISO.


### Security

 - Currently, we focus build and development workflow. In the future, at release version, we will increase security between Edge and Central.

  

### Extension



### Database

- Edge Device only process data, all data will transfer to iView System Database. 

## Page setup



  

## License

  

## Links

  

*  [Web site]()

*  [Documentation]()

*  [Forum](/)

*  [Issue tracker]()

*  [Source code]()
