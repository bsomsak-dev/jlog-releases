# workctl

CLI สำหรับนำเวลาจาก Kawari ไปสร้าง Jira Worklog

## ติดตั้ง

ต้องมี macOS, Node.js 22+, npm และ [Jira Cloud API token](https://id.atlassian.com/manage-profile/security/api-tokens)

```sh
node --version
npm --version
```

```sh
curl -fsSL https://raw.githubusercontent.com/bsomsak-dev/workctl-releases/main/install.sh | sh
```

ตัวติดตั้งดาวน์โหลด `workctl` และ Playwright Chromium จากนั้นเปิด setup wizard
ถ้าปิดก่อนตั้งค่าเสร็จ รันใหม่:

```sh
workctl setup
```

เตรียม 5 อย่าง:

- **Jira base URL** — เฉพาะ origin เช่น `https://example.atlassian.net`
- **Jira email** — บัญชีเดียวกับ API token
- **Jira API token**
- **Kawari timesheet URL** — URL เต็มของหน้า timesheet
- **Timezone** — `Asia/Bangkok`

Configuration เก็บที่ `~/.config/workctl/config.json`
API token เก็บเป็น plain text — ใช้บนเครื่องส่วนตัวที่เชื่อถือได้เท่านั้น

## เริ่มใช้งาน

### 1. ตรวจความพร้อม

```sh
workctl jlog doctor
```

ต้องเห็น `PASS` ทุกรายการ (config, Jira auth, Playwright Chromium)

```sh
workctl jlog config show
```

ดู configuration ที่ใช้อยู่ (token ถูกซ่อน)

### 2. Sync (คำสั่งเดียว ครบทุกขั้นตอน)

```sh
workctl jlog sync
```

`sync` เป็น guided command — ทำงานทั้งหมดในครั้งเดียว:

1. ถามช่วงวันที่ โดยเลือกเดือนปัจจุบันพร้อมแสดงวันเริ่ม–วันจบไว้เป็นค่าเริ่มต้น
   หรือเลือกกรอก `From` และ `To` เอง
2. scrape ข้อมูลจาก Kawari timesheet
3. แสดง preview ทั้งหมดที่จะสร้าง
4. ถามยืนยัน `Create N worklog(s) totaling Xh?`
5. สร้าง Jira worklog
6. verify ผลอัตโนมัติ

เมื่อกรอกช่วงเอง ระบบใส่วันแรกและวันสุดท้ายของเดือนปัจจุบัน
(`Asia/Bangkok`) ไว้ให้แก้ ใช้รูปแบบ `YYYY-MM-DD` และต้องอยู่ภายในเดือนเดียวกัน
หากส่ง `--from` และ `--to` จะข้ามหน้าถาม:

```sh
workctl jlog sync --from 2026-07-01 --to 2026-07-04
```

การรัน `sync` แบบ non-interactive โดยไม่ส่งวันที่ยังใช้เดือนปัจจุบันอัตโนมัติ

เมื่อรันใน terminal ข้อความถาม ความคืบหน้า ผลลัพธ์ และ error จะแสดงในรูปแบบ
guided เดียวกัน รวมถึงตอนที่ต้อง login หรือเลือกเดือนใน browser แล้วกลับมากด
Enter ส่วน `--help`, `--version` และการรันแบบ non-interactive ยังคงเป็น plain text

รันซ้ำจะข้ามรายการที่สร้างสำเร็จแล้ว ไม่มี duplicate
ถ้า Jira issue ไม่มีอยู่จริง `workctl jlog` จะให้ใส่ key ที่ถูกต้อง (เฉพาะ batch นี้ ไม่เปลี่ยน Kawari)

### คำสั่งอื่น ๆ

```sh
workctl jlog preview                              # ดู preview อย่างเดียว (ไม่อนุมัติ ไม่เขียน)
workctl jlog verify  --from 2026-07-01 --to 2026-07-04   # ตรวจผลทีหลัง

workctl jlog rollback --from 2026-07-01 --to 2026-07-04 --dry-run   # ดูก่อนลบ
workctl jlog rollback --from 2026-07-01 --to 2026-07-04             # ลบ worklog จริง
```

ถ้ารัน `workctl jlog rollback` หรือ `workctl jlog rollback --dry-run` โดยไม่ส่งวันที่ ระบบจะถาม
ช่วงวันที่แบบเดียวกับ `sync` การส่ง `--from` และ `--to` จะข้ามหน้าถาม

Rollback ลบเฉพาะ worklog ที่ `jlog` สร้างไว้ และ restore เวลาเป็น Jira Remaining Estimate
ถ้า entry ย้ายไป issue ใหม่ ให้ระบุของเดิมด้วย `--issue OLD-KEY`

## คำสั่งทั้งหมด

```
workctl setup
workctl jlog configure
workctl jlog config show
workctl jlog doctor
workctl jlog sync     [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
workctl jlog preview  [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
workctl jlog verify   [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
workctl jlog rollback [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--issue KEY] [--dry-run]
workctl jlog update
workctl --help
```

เพิ่ม `--export csv` หรือ `--export json` เพื่อบันทึกไฟล์ไว้ที่ `~/.local/share/workctl/jlog/audit-exports/`

## อัปเดต

```sh
workctl jlog update
```

ตรวจสอบ release ล่าสุดจาก GitHub ยืนยัน checksum แล้วพิมพ์ `yes` เพื่อติดตั้ง

## ถอนการติดตั้ง

```sh
curl -fsSL https://raw.githubusercontent.com/bsomsak-dev/workctl-releases/main/uninstall.sh | sh
```

ลบทั้งหมดรวม config, token, state:

```sh
curl -fsSL https://raw.githubusercontent.com/bsomsak-dev/workctl-releases/main/uninstall.sh | sh -s -- --purge
```

## ปัญหาที่พบบ่อย

- **Setup ไม่สำเร็จ** — `workctl setup` แล้วเลือก capability ที่ต้องการทำซ้ำ
- **Jira auth FAIL** — ตรวจ URL, email, token ใหม่ด้วย `workctl jlog configure`
- **Kawari session หมด** — รัน `workctl jlog sync` อีกครั้ง แล้วล็อกอินในหน้าต่าง Chromium
- **Playwright Chromium FAIL** — ติดตั้ง `workctl` ใหม่
- **ช่วงวันที่ผิด** — ต้องใส่ `--from` `--to` คู่กัน รูปแบบ `YYYY-MM-DD` ภายในเดือนเดียวกัน
- **Sync Conflict** — ข้อมูลใน Kawari เปลี่ยนหลังจาก sync ไปแล้ว แก้ที่ Kawari ให้ตรงกันก่อน
- **Sync ไม่ครบทุกรายการ** — รัน `workctl jlog sync` อีกครั้งด้วยช่วงวันที่เดิม ที่สำเร็จแล้วจะถูกข้าม
- **Rollback ไม่เจอ worklog** — ถ้า entry ย้าย issue ให้ `--issue OLD-KEY`
