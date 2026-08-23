# ============================================================
# Stage 1: Build — Node.js LTS (compile React/Vite app)
# ============================================================
FROM node:22-alpine AS build

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and produce production build into /app/dist
COPY index.html ./
COPY vite.config.js ./
COPY public ./public
COPY src ./src

# Same-origin /api for GKE Gateway. Local `npm run dev` still uses localhost:8080 by default.
ARG VITE_API_BASE_URL=/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

RUN npm run build

# ============================================================
# Stage 2: Runtime — Nginx only (no Node, no source)
# ============================================================
FROM nginx:1.27-alpine AS runtime

# Remove default site content
RUN rm -rf /usr/share/nginx/html/*

# Copy production build from Stage 1
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
