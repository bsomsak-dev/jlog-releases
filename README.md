# jlog releases

`jlog` เป็น CLI สำหรับนำเวลาจาก Kawari ไปสร้าง Jira Worklog โดยให้ตรวจสอบ
รายการและยืนยันก่อนเขียนข้อมูลจริง

## สิ่งที่ต้องมีก่อนติดตั้ง

- macOS
- Node.js 22 ขึ้นไป พร้อม `npm`
- บัญชีที่เข้าใช้ Kawari timesheet ได้
- Jira Cloud email และ [Jira API token](https://id.atlassian.com/manage-profile/security/api-tokens)

ตรวจสอบเครื่องมือที่จำเป็นได้ด้วย:

```sh
node --version
npm --version
```

## ติดตั้ง

```sh
curl -fsSL https://raw.githubusercontent.com/bsomsak-dev/jlog-releases/main/install.sh | sh
```

ตัวติดตั้งจะดาวน์โหลด `jlog` และ Playwright Chromium ที่ตรงกับ release
จากนั้นจะเปิด setup wizard ถ้ายังไม่มี configuration ที่ใช้งานได้

ถ้า setup wizard ไม่เปิด หรือปิดไปก่อนตั้งค่าเสร็จ ให้รัน:

```sh
jlog setup
```

เตรียมข้อมูลต่อไปนี้สำหรับ setup:

- **Jira base URL** — เฉพาะ origin เช่น `https://example.atlassian.net`
  ไม่ใส่ path ของ project หรือ issue
- **Jira email** — email ของบัญชี Jira
- **Jira API token** — token ของบัญชีเดียวกับ email
- **Kawari timesheet URL** — URL เต็มของหน้า timesheet
- **Timezone** — ใช้ `Asia/Bangkok`

Configuration จะถูกเก็บที่ `~/.config/jlog/config.json` โดย Jira API token
เก็บเป็น plain text ในไฟล์นี้ ควรใช้ `jlog` บนเครื่องส่วนตัวที่เชื่อถือได้เท่านั้น

## เริ่มใช้งานครั้งแรก

### 1. ตรวจสอบความพร้อม

```sh
jlog doctor
```

ควรเห็น `PASS` สำหรับ configuration, data directory, Jira authentication และ
Playwright Chromium ถ้ามีรายการ `FAIL` ให้แก้ตามรายละเอียดที่แสดงก่อนทำขั้นตอนต่อไป

ดู configuration ที่กำลังใช้งานได้ด้วยคำสั่งด้านล่าง โดย token จะถูกซ่อนเสมอ:

```sh
jlog config show
```

### 2. เตรียมข้อมูลใน Kawari

Timesheet Entry ที่ต้องการสร้างเป็น Jira Worklog ต้องมี Jira issue key
เพียงหนึ่งตัวใน Description เช่น:

```text
PROJ-123 Implement login validation
```

- ไม่มี Jira key: รายการจะเป็น Unmapped Entry และถูกข้ามพร้อมคำเตือน
- มี Jira key มากกว่าหนึ่งตัว: รายการไม่ถูกต้องและจะหยุดทั้ง Sync Batch

### 3. Preview ก่อนเขียน Jira

```sh
jlog preview
```

`preview` อ่านข้อมูลจาก Kawari และ Jira เพื่อแสดงรายการที่จะ `Create`, `Skip`,
เตือน หรือพบ conflict โดยไม่เขียนข้อมูลลง Jira

ครั้งแรก Playwright Chromium อาจเปิดหน้าต่างให้ล็อกอิน Kawari เมื่อเข้าสู่ระบบแล้ว
ให้กลับมาดูผลลัพธ์ใน Terminal

ถ้าไม่ระบุวันที่ `jlog` จะใช้วันจันทร์ถึงวันอาทิตย์ของสัปดาห์ปัจจุบันตาม
`Asia/Bangkok`

กำหนดช่วงวันที่เองได้ โดยต้องใส่ `--from` และ `--to` คู่กัน รูปแบบ
`YYYY-MM-DD` และอยู่ภายในเดือนเดียวกัน:

```sh
jlog preview --from 2026-07-01 --to 2026-07-04
```

### 4. Sync ไปยัง Jira

เมื่อผล preview ถูกต้องแล้ว ให้ใช้ช่วงวันที่เดียวกันกับที่ตรวจสอบ:

```sh
jlog sync --from 2026-07-01 --to 2026-07-04
```

`sync` จะแสดง preview อีกครั้งก่อนเขียน Jira หากต้องการดำเนินการต่อ ต้องพิมพ์
`yes` ตามข้อความยืนยัน:

```text
Create 3 Jira worklog(s) totaling 12h? Type yes to continue: yes
```

คำตอบอื่นจะยกเลิกโดยไม่สร้าง Jira Worklog การรันคำสั่งเดิมซ้ำจะข้าม Worklog
ที่ `jlog` สร้างสำเร็จแล้ว จึงไม่สร้างรายการซ้ำ

### 5. ตรวจสอบผล

`sync` จะตรวจสอบผลให้อัตโนมัติหลังเขียนเสร็จ และสามารถตรวจซ้ำภายหลังได้ด้วย:

```sh
jlog verify --from 2026-07-01 --to 2026-07-04
```

`verify` เป็นคำสั่งแบบ read-only และไม่เขียนข้อมูลลง Jira

## คำสั่งที่ใช้บ่อย

```text
jlog setup
jlog config show
jlog doctor
jlog preview [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
jlog sync    [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
jlog verify  [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--export csv|json]
jlog update
jlog --help
jlog <command> --help
```

เพิ่ม `--export csv` หรือ `--export json` เพื่อบันทึก audit export ไว้ที่
`~/.local/share/jlog/audit-exports/` เช่น:

```sh
jlog preview --from 2026-07-01 --to 2026-07-04 --export csv
```

อัปเดตเป็น stable release ล่าสุด:

```sh
jlog update
```

คำสั่งจะขอให้พิมพ์ `yes` ก่อนติดตั้ง update

## แก้ปัญหาที่พบบ่อย

### Setup ไม่สำเร็จ หรือ configuration ไม่ถูกต้อง

รัน setup ใหม่ แล้วตรวจสอบผล:

```sh
jlog setup
jlog doctor
```

Jira base URL ต้องเป็น HTTPS origin เช่น `https://example.atlassian.net`
และ Jira email ต้องเป็นบัญชีเดียวกับ API token

### `jlog doctor` แสดง `FAIL`

อ่านรายละเอียดต่อท้ายรายการที่ fail:

- **Jira authentication** — ตรวจ Jira URL, email และ API token ด้วย `jlog setup`
- **Config directory/file** — รัน `jlog setup` ใหม่เพื่อสร้างไฟล์และ permission
  ที่ถูกต้อง
- **Playwright Chromium** — ติดตั้ง `jlog` ใหม่ เพื่อให้ installer ดาวน์โหลด
  Chromium ที่ตรงกับ release

### เปิด Kawari ไม่ได้หรือ session หมดอายุ

รัน `jlog preview` อีกครั้ง แล้วล็อกอินในหน้าต่าง Chromium ที่เปิดขึ้น
Browser profile จะถูกเก็บไว้ที่ `~/.local/share/jlog/browser-profile/`

### Error เรื่องช่วงวันที่

- ต้องระบุ `--from` และ `--to` พร้อมกัน
- ใช้รูปแบบ `YYYY-MM-DD`
- วันที่เริ่มต้องไม่อยู่หลังวันที่สิ้นสุด
- ช่วงวันที่ต้องอยู่ภายในเดือนเดียวกัน
- ถ้าสัปดาห์ปัจจุบันคร่อมเดือน ต้องระบุช่วงวันที่เอง

ตัวอย่าง:

```sh
jlog preview --from 2026-07-01 --to 2026-07-05
```

### รายการถูกข้ามหรือทั้ง batch ถูกหยุด

- Description ไม่มี Jira key: รายการถูกข้ามเป็น Unmapped Entry
- Description มีหลาย Jira key: แก้ให้เหลือเพียงหนึ่ง key
- ข้อมูลวันที่ ระยะเวลา Project หรือ Description ไม่ถูกต้อง: แก้ใน Kawari
  แล้วรัน `preview` ใหม่
- Sync Conflict: ข้อมูลใน Kawari ต่างจาก Jira Worklog ที่เคย sync ต้องตรวจและ
  แก้ข้อมูลต้นทางหรือ Worklog ให้ถูกต้องก่อนรันใหม่

### Sync สร้าง Worklog สำเร็จเพียงบางรายการ

แก้สาเหตุที่แสดงใน Terminal แล้วรัน `jlog sync` ด้วยช่วงวันที่เดิมอีกครั้ง
รายการที่สร้างสำเร็จแล้วจะถูก `Skip` และ `jlog` จะลองสร้างเฉพาะรายการที่ยังขาด
