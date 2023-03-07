const express = require('express')

const app = express()

app.get('/', (_req, res) => {
	res.send(`
		Hello World!
		The NODE_ENV is ${process.env.NODE_ENV}.
		Datetime now: ${new Date().toISOString()}.
		The MY_INPUT_ENV_VAR is ${process.env.MY_INPUT_ENV_VAR}.
	`)
})

app.listen(process.env.PORT, () => {
	console.log(`Listening on port ${process.env.PORT}`)
})
