FROM node:22-alpine

WORKDIR /app

COPY package.json ./
COPY src ./src

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8787
ENV AM_STATE_FILE=/data/state/am-studio-state.json
ENV AM_MEDIA_DIR=/data/media

RUN mkdir -p /data/state /data/media && chown -R node:node /app /data

USER node

EXPOSE 8787

CMD ["node", "src/server.js"]
