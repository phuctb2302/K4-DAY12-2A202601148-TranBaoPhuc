# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (Production-ready)
#
# Multi-stage build:
#   - Stage `builder`: cài toàn bộ dependency (có thể cần compiler)
#   - Stage `runtime`: chỉ copy KẾT QUẢ sang, image nhỏ gọn < 400MB
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: Builder ──────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Copy requirements TRƯỚC để tận dụng Docker layer cache:
# Chỉ khi requirements.txt thay đổi, bước pip install mới chạy lại.
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Tạo user không có quyền root → giảm bề mặt tấn công
RUN useradd --create-home --uid 10001 appuser

WORKDIR /app

# Copy kết quả pip install từ builder sang (không mang theo compiler)
COPY --from=builder /install /usr/local

# Copy source code (SAU pip install để tận dụng cache)
COPY app ./app
COPY utils ./utils

# Chuyển sang user thường (không phải root)
USER appuser

# Healthcheck gọi vào /healthz — dùng urllib thay vì curl (slim không có curl)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz').read()" || exit 1

# Cloud platform (Railway/Render) tự gán cổng qua biến $PORT
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
