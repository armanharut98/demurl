import put_method from "./post_lambda.js"

console.log(await put_method({ body: { url: "facebook.com" }}))
