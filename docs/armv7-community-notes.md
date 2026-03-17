# ARMv7 / Adreno 3xx community notes (Flutter raster crash)

Tổng hợp ngắn các hướng xử lý thường được cộng đồng dùng cho nhóm máy ARMv7 + Adreno 3xx (Note 3, ROM Lineage/crDroid cũ):

1. **Tránh fallback quá mạnh kiểu ép software layer toàn màn hình**
   - Nhiều báo cáo cho thấy có thể gây UI đen / render rỗng trên một số ROM cũ.
2. **Giữ renderer theo đường ổn định hơn (Skia/OpenGL cũ)**
   - Tránh các path render mới hoặc hiệu ứng nặng dễ kích lỗi driver vendor.
3. **Giảm workload raster thay vì đổi toàn bộ UI framework**
   - Hạn chế blur/saveLayer/opacity chồng.
   - Giảm kích thước decode ảnh (`cacheWidth/cacheHeight`) và dùng `FilterQuality.low` trên thiết bị yếu.
4. **Target chính xác nhóm ARMv7 32-bit**
   - Bật compat mode theo ABI (`armeabi-v7a`) + fingerprint thiết bị cũ, tránh ảnh hưởng thiết bị mới.
5. **Nếu vẫn crash**
   - Cân nhắc degrade sâu hơn ở màn dễ crash hoặc đưa cảnh báo hỗ trợ hạn chế cho ROM legacy.

> Tài liệu này chỉ nhằm ghi nhớ hướng triển khai thực dụng trong app này; nguyên nhân gốc vẫn là driver/vendor blob.
