# Session 10 - Bài 4: Custom Network và Named Volume

## 1. Mục tiêu

Tạo mạng Docker riêng để các container giao tiếp với nhau qua tên container, đồng thời sử dụng Named Volume để lưu trữ dữ liệu PostgreSQL bền vững.

## 2. Các thành phần

- **Network:** `app-net` - mạng Bridge riêng cho các container.
- **Volume:** `db-data` - lưu dữ liệu PostgreSQL.
- **Database:** `db-server` - container chạy PostgreSQL 15 Alpine.
- **Container kiểm tra mạng:** `app-container` - dùng để kiểm tra DNS và giao tiếp nội bộ với database.

Lưu ý: `app-container` là container kiểm tra mạng, chưa phải Backend Web API thực tế vì đề chưa cung cấp image backend.

## 3. Tạo Network và Volume

```bash
docker network create app-net
docker volume create db-data
```

## 4. Khởi chạy các container

Chạy script `commands.sh` để tạo Network, Volume và khởi chạy các container.

Database được gắn Named Volume bằng tham số:

```bash
-v db-data:/var/lib/postgresql/data
```

Container kiểm tra mạng được cấu hình biến `DB_HOST=db-server` để sử dụng tên container database làm hostname.

## 5. Kiểm tra Network và DNS

```bash
docker network ls
docker volume ls
docker network inspect app-net
docker exec -it app-container ping -c 2 db-server
```

Kết quả thực tế: ping thành công 2/2 gói tin, không mất gói. Docker DNS phân giải tên `db-server` thành địa chỉ IP nội bộ.

## 6. Kiểm tra Data Persistence

Tạo bảng, thêm dữ liệu và truy vấn trong PostgreSQL:

```bash
docker exec db-server psql -U appuser -d appdb -c "CREATE TABLE IF NOT EXISTS persistence_test (id SERIAL PRIMARY KEY, message TEXT NOT NULL);"

docker exec db-server psql -U appuser -d appdb -c "INSERT INTO persistence_test (message) VALUES ('Docker volume persistence works');"

docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

Xóa container database:

```bash
docker rm -f db-server
```

Tạo lại container và gắn cùng Named Volume:

```bash
docker run -d --name db-server --network app-net -e POSTGRES_USER=appuser -e POSTGRES_PASSWORD=apppass123 -e POSTGRES_DB=appdb -v db-data:/var/lib/postgresql/data postgres:15-alpine
```

Truy vấn lại dữ liệu:

```bash
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

Kết quả thực tế: dữ liệu `Docker volume persistence works` vẫn còn sau khi xóa và tạo lại container database.

## 7. Kết luận

Đã tạo và kiểm tra thành công Custom Bridge Network `app-net` và Named Volume `db-data`. Hai container giao tiếp được qua hostname `db-server`. Dữ liệu PostgreSQL được giữ nguyên khi xóa và tạo lại container nhờ Named Volume.
