FROM node:18-alpine

WORKDIR /app

ENV \
	NODE_ENV=production \
	PORT=8080

EXPOSE ${PORT}

COPY package*.json ./
RUN npm ci

COPY . .

CMD [ "node", "index.js"]
