# ======================================================================
# E-Book Backend API - Node.js / Express (Docker)
# Node 20 LTS (alpine) - compatible with express ^4.19, mysql2, multer,
# bcryptjs, jsonwebtoken, cors, dotenv (all pure-JS, no native build).
# Node version is not declared in Backend/package.json, so a stable LTS
# image is used deliberately.
# ======================================================================
FROM node:20-alpine

LABEL org.opencontainers.image.title="E-Book Backend API"
LABEL org.opencontainers.image.description="Node.js Express RESTful API + persistent uploads volume"

# Use a dedicated non-root user for the runtime
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

# Install production dependencies first (better layer caching).
# .dockerignore excludes node_modules/.git/.env/etc from the build context.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy application source (node_modules/.env/.git/uploads excluded)
COPY . .

# Ensure the runtime uploads directory exists (contents come from the
# persistent `backend-uploads` volume, seeded separately - never baked here).
RUN mkdir -p /app/uploads && chown -R app:app /app

USER app

EXPOSE 5000

# project start command (package.json "start" => node server.js)
CMD ["npm", "start"]