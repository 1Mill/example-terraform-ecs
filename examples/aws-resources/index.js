const express = require('express')

const app = express()

app.get('/', (_req, res) => {
	res.send(`Hello World! The NODE_ENV is ${process.env.NODE_ENV}.`)
})

app.listen(process.env.PORT, () => {
	console.log(`Listening on port ${process.env.PORT}`)
})
