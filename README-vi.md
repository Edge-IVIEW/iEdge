
  

<a  href="https://iview.vn/">

<img  src="https://i.imgur.com/EORKMiE.jpg"  alt="IVIEW logo"  title="IVIEW Edge AI Solution"  align="right"  height="60"  />

</a>

  

Giải pháp Edge AI IVIEW

======================

:star: Star us on GitHub — it helps!

  

[iEdge](https://iview.vn) là một nền tảng triển khai và quản lý các ứng dụng AI(trí tuệ nhân tạo) lên các thiết bị ARM như Jetson Nano,...

iEdge giúp quản lý các thiết bị biên - các thiết bị được triển khai AI trong mô hình [điện toán biên](https://smartfactoryvn.com/technology/internet-of-things/edge-computing-dien-toan-ranh-gioi-la-gi-vai-tro-cua-edge-computing-trong-cong-nghiep-4-0/) thông qua Internet.

![iEdge demo](https://i.imgur.com/xC4qH5J.png)


## Nội dung
-  [Cài đặt](#installation)
-  [Composer](#composer)
-  [Extension](#extension)
-  [Database](#database)
-  [Page setup](#page-setup)
-  [Upload the page tree file](#upload-the-page-tree-file)-  [Go to the import view](#go-to-the-import-view)
-  [Import the page tree](#import-the-page-tree)
-  [SEO-friendly URLs](#seo-friendly-urls)
-  [License](#license)
-  [Links](#links)

## Tạo token xác thực cho thiết bị mới

 [Liên hệ](https://iview.vn/) với chúng tôi để yêu cầu tài khoản demo.

Truy câp https://go.iview.vn/ và đăng nhập vào tài khoản được cấp.

Chọn phần **Chỉnh sửa hệ thống**, sau đó chọn **Quản lý BoxAI**:

  


![](https://i.imgur.com/vsd3zV6.png)

  

Nhấn vào **Tạo token cho boxAI** và lưu lại token này, token này sẽ được sử dụng trong quá trình đăng kí box

  

![](https://i.imgur.com/Xawkp91.png)

  

## Chuẩn bị trước khi cài đặt

Phiên bản hiện tại được thực hiện triển khai trên Jetson Nano.

Chuẩn bị trước một board Jetson Nano b01, màn hình(kết nối qua cáp HDMI), bàn phím và chuột (Kết nối qua USB). 
Thẻ nhớ MicroSD tối thiểu 32 GB
Một kết nối mạng Ethernet.
Thiết bị này sẽ được đăng ký để triển khai các model AI và được quản lý qua Internet.

## Tải ISO và boot ISO vào thẻ nhớ

[Liên hệ](https://iview.vn/) với chúng tôi để yêu cầu file ISO.

File ISO là file chứa các gói cơ bản, cần thiết cho việc đăng ký thiết bị mới.

Sau khi nhận được file ISO, tiến hành boot file ISO vào thẻ nhớ MicroSD đã được chuẩn bị sử dụng Rufus hoặc phần mêm tương tự.

### Installation
- Lắp thẻ nhớ SD vào Jetson Nano và khởi động Jetson Nano sau đó đợi khoảng hai phút để  màn hình hiển thị giao diện đăng kí thiết bị.

-  **BƯỚC 1**: Ở phần **Xác thực** > **1. Cấu hình mạng** > chọn mục **Phương thức kết nối**. Nếu Jetson Nano kết nối đến mạng có DHCP, **chọn kết nối đến mạng dây** và click chọn kiểm tra đường truyền để kiểm tra kết nối mạng. Đợi một lúc cho đến khi cấu hình mạng thành công sẽ có thông báo **Thay đổi network thành công** thì thực hiện bước tiếp theo. Nếu cấu hình mạng không thành công, thực hiện kết nối bằng các phương thức kết nối khác.

![](https://i.imgur.com/dM5Uv2q.png)

- **Bước 2**: Ở phần **Xác thực** > **2. Nhập thông tin tài khoản**, Nhập đầy đủ các thông tin tài khoản, mật khẩu (tài khoản và mật khẩu đăng nhập trên go.iview.vn), token (được cấp ở bước trước), và tên cho thiết bị mới này sau đó click chọn **Xác thực**. Nếu xác thực thành công, giao diện sẽ hiển thị thêm phần chọn group để cấu hình nhóm cho thiết bị mới, chọn một nhóm và click chọn **Bước tiếp theo**.

![](https://i.imgur.com/49I4AME.png)

![]()

- **Bước 3**: Chọn chức năng để triển khai lên thiết bị. Ví dụ chọn **Chấm công** để triển khai chức năng chấm công bằng khuân mặt lên thiết bị. Sau đó click chọn **Bước tiếp theo**.
 ![](https://i.imgur.com/zvxTqr6.png)

  - **Bước 4**: Ở phần **Cấu hình Camera**, phần chọn camera có hai tùy chọn là **webcam** và **camera**. Tùy theo nhu cầu chọn camera phù hợp. Nếu chọn **camera**, cấu hình thêm đường dẫn luồng cho camera IP, chức năng cho camera, và vị trí của camera sau đó click **Kiểm tra tình trạng camera**. Nếu giao diện trả về thông báo *Tất cả các camera đều hoạt động* thì click chọn **Hoàn thành** để tiếp tục thiết lập thiết bị.
  
  ![](https://i.imgur.com/hR9yOgq.png)
  

### Sử dụng

- Đợi 3-5 phút cho đến khi có yêu cầu khởi động lại thiết bị. Trong suốt quá trình này cần giữ kết nối Internet cho thiết bị.


### Đóng gói

- Tất cả những gì cần thiết để quản lý thiết bị đều được đóng trong file ISO.
  

### Cơ sở dữ liệu - database

- Edge Device chỉ xử lý dữ liệu và gửi về Hệ thống tập trung để lưu trữ.

  

## Page setup

  
  
  

  

## License

  

  

## Links

  

  

*  [Web site]()

  

*  [Documentation]()

  

*  [Forum](/)

  

*  [Issue tracker]()

*  [Source code]()
