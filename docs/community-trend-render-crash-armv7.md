# Community trend notes: Flutter render crash on ARMv7/Adreno 3xx

Tổng hợp ngắn theo xu hướng cộng đồng khi gặp crash/vỡ UI ở nhóm máy cũ (ARMv7 + GPU driver đời cũ):

## 1) Nâng version Flutter/engine trước khi workaround UI
- Nhiều case cải thiện sau khi lên Flutter stable mới hơn do engine/Skia fixes.
- Workaround UI thường chỉ giảm triệu chứng, không xử lý gốc nếu driver + engine path bị lỗi.

## 2) Nâng Android build toolchain đồng bộ
- Kotlin/AGP/Gradle cũ có thể làm build path và dependency graph lỗi thời.
- Ưu tiên cập nhật AGP + Gradle wrapper + Kotlin theo cặp tương thích.

## 3) Nếu vẫn lỗi trên ARMv7
- Ép render path cũ hơn (disable impeller).
- Có thể dùng software rendering cho nhóm thiết bị legacy (đổi lại hiệu năng).

## 4) Kết luận thực dụng
- Thứ tự thường hiệu quả: **nâng Flutter + build toolchain** -> nếu chưa hết thì mới bật fallback render riêng cho ARMv7.
