# ARMv7 UI render corruption: reality check & next steps

## Short answer
Không có “silver bullet” từ cộng đồng cho nhóm máy ARMv7 + Adreno 3xx + ROM custom cũ.

## Những gì cộng đồng thường làm
1. Nâng Flutter/engine và toolchain Android.
2. Tắt renderer mới (Impeller), ép đường render cũ hơn.
3. Nếu vẫn lỗi: dùng software rendering cho nhóm thiết bị cũ (đổi lấy hiệu năng).
4. Nếu vẫn không ổn định: giảm/bỏ hỗ trợ thiết bị legacy (device exclusion/safe mode).

## Có nên tiếp tục nâng version?
Có, nhưng theo chiến lược có kiểm chứng:

- Chỉ test các mốc lớn, không nâng vô hạn.
- Sau mỗi lần nâng, so sánh:
  - số crash SIGSEGV raster
  - mức vỡ UI
  - độ usable của app
- Nếu 2-3 mốc stable mới vẫn không cải thiện trên Note 3/ARMv7 thì coi như giới hạn driver, không phải app.

## Khuyến nghị cho project này
1. Giữ branch chính ổn định UI/function.
2. Tạo 1 flavor legacy riêng ARMv7:
   - tắt impeller
   - ưu tiên software rendering nếu cần
3. Nếu vẫn vỡ UI: hiển thị cảnh báo tương thích và cho người dùng chọn “legacy safe mode” hoặc dừng hỗ trợ thiết bị đó.

## Kết luận
- Có thể tiếp tục nâng version, nhưng kỳ vọng thực tế: **khả năng fix triệt để trên Note 3 rất thấp**.
- Mốc quyết định nên dựa trên crash metric thực tế thay vì tiếp tục tweak UI.
