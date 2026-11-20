# Package the Node app as a container image (the most common "artifact" today).
#   docker build -t demo-app:1.0.0 .
#   docker run -p 3000:3000 -e APP_NAME=blue demo-app:1.0.0

FROM node:20-alpine
WORKDIR /app

# Copy dependency files first -> Docker caches this layer between builds
COPY package*.json ./
RUN npm install --omit=dev

COPY server.js ./

ENV PORT=3000
EXPOSE 3000

# Run as non-root user that ships with the image
USER node
CMD ["node", "server.js"]
