# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Trần Bảo Phúc  Mã học viên: 2A202601148

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu để `api_token` mặc định là `"changeme"`, ứng dụng sẽ khởi động bình thường. Khi quên cấu hình biến môi trường trên Production, ứng dụng vẫn chạy và vô tình cho phép bất kỳ ai dùng token `"changeme"` truy cập trái phép. Việc không để mặc định giúp app "chết sớm" ngay lúc khởi động, giúp ta phát hiện ngay lập tức lỗi thiếu cấu hình trước khi để lộ hổng bảo mật ra Internet.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> `{"level": "INFO", "event": "chat_completed", "client_id": "sv-test", "usd_cost": 0.0001, "timestamp": "..."}`
> Hai việc làm được: 1) Dễ dàng đẩy vào các hệ thống quản lý log (ELK, Datadog) để filter và query chính xác (ví dụ tìm tất cả log của client_id="sv-test"). 2) Có thể dùng log để tự động tính tổng chi phí (sum usd_cost) hoặc vẽ biểu đồ dashboard mà không cần dùng regex phức tạp để bóc tách chuỗi như log text thông thường.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | ... MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Bản 1 stage: ~1000MB, Bản multi-stage: ~150MB.
> Phần dung lượng chênh lệch chính là hệ điều hành đầy đủ, các công cụ build (compiler như gcc, make), bộ nhớ đệm (pip cache) và các file trung gian sinh ra trong quá trình cài đặt thư viện. Multi-stage loại bỏ toàn bộ những thứ này và chỉ copy nguyên thư mục `.venv` gọn nhẹ sang stage cuối để chạy.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi sửa code trong `main.py`, các layer cài đặt thư viện (như `COPY requirements.txt` và `RUN pip install`) nằm ở trên sẽ được dùng lại từ cache. Chỉ có layer `COPY . .` (chép code) và các layer bên dưới nó phải chạy lại.
> Nếu đặt `COPY . .` lên trước `RUN pip install`, chỉ cần sửa một dòng code nhỏ thì layer COPY sẽ bị đánh dấu thay đổi, làm vô hiệu hóa toàn bộ cache của lệnh cài thư viện phía sau, khiến Docker phải tốn thời gian tải và cài lại toàn bộ thư viện từ đầu.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Nếu chạy bằng quyền root, một lỗ hổng trong code Python (ví dụ hacker gửi payload thực thi lệnh RCE) sẽ cho phép hacker chạy lệnh với quyền root bên trong container. Nếu có thêm lỗi "container breakout", chúng có thể chiếm luôn quyền quản trị cao nhất của máy host.
> Lệnh `USER` cắt đứt chuỗi đó bằng cách giới hạn quyền của app ngay từ đầu. Dù hacker khai thác được code Python, chúng chỉ có thể chạy lệnh với tư cách user thường, không thể cài cắm mã độc sâu vào hệ thống.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

> Chuẩn HTTP yêu cầu trả về header `WWW-Authenticate: Bearer` để các HTTP Client (như trình duyệt, Postman) biết được phương thức xác thực mà server mong muốn để xử lý và hiển thị thông báo/nhập liệu hợp lý.
> Trả cùng một lỗi cho cả 3 trường hợp để chống tấn công dò mật khẩu (Enumeration Attack/Guessing). Nếu báo lỗi quá chi tiết, hacker sẽ biết được là chúng đã cấu trúc đúng scheme nhưng sai token, tạo điều kiện cho chúng brute-force (thử hàng loạt token). Mập mờ sẽ khiến chúng không biết sai ở bước nào.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Gửi được đúng 10 request trước khi bị lỗi 429 (vì sức chứa tối đa của bucket là 10).
> Nếu bỏ đoạn `min(capacity, ...)` trong hàm `available()`, bucket sẽ tích lũy vô hạn. Sau 10 phút, bucket sẽ có 100 token. Khi đó client có thể xả 100 request liên tiếp, phá vỡ giới hạn burst (bùng nổ) của hệ thống, khiến server có nguy cơ bị quá tải và sập khi có nhiều client làm như vậy cùng lúc.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> Với mức $30/tháng, nếu bị tấn công thì chỉ trong 1 đêm thiệt hại sẽ là toàn bộ $30. Dịch vụ của client đó sẽ bị khóa cứng trong 29 ngày còn lại của tháng, không thể phục hồi.
> Với mức $1/ngày, thiệt hại tối đa chỉ là $1 cho đêm đó. Dịch vụ sẽ tự động hồi phục lại vào sáng hôm sau (vì ngân sách được reset), vừa giới hạn được rủi ro tài chính đột ngột vừa duy trì được tính khả dụng lâu dài cho dịch vụ.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp chung và Redis bị sập 30s, hàm kiểm tra gộp sẽ trả về lỗi. Các hệ thống như Kubernetes/Load Balancer sẽ thấy app báo lỗi health check nên lầm tưởng container đã chết. Kết quả là nó sẽ liên tục "kill" và khởi động lại toàn bộ 3 container, gây downtime toàn hệ thống.
> Nhờ tách riêng, `/healthz` vẫn trả 200 (app không chết), chỉ có `/readyz` trả 503. Load Balancer sẽ không giết container mà chỉ tạm ngưng gửi traffic vào. Sau 30s Redis sống lại, hệ thống tự động phục hồi mà không container nào bị restart.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lỗi gặp: Deploy Render bị fail ở bước khởi động vì ứng dụng cố bám vào cổng cố định 8000 trong khi Render cấp cổng ngẫu nhiên.
> Tìm ra nguyên nhân: Xem trực tiếp log ở mục "Events / Logs" trên trang quản lý service của Render, thấy báo lỗi `address already in use` hoặc `unrecognized arguments: $PORT`.
> Cách sửa: Sửa tham số khởi động uvicorn thành tự động nhận biến môi trường PORT từ cloud, và cập nhật mục Start Command trên Render.
