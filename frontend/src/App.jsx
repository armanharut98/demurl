import { useState } from 'react'
import axios from "axios"
import './App.css'

function App() {
  const [url, setUrl] = useState("")
  const [shortenedUrl, setShortenedUrl] = useState("")

  const baseUrl = "https://uom3hqkkql.execute-api.us-east-1.amazonaws.com/dev/shorten"

  const protocol = "http://"

  const shortenUrl = async (event) => {
    event.preventDefault()
    let absoluteUrl = url
    if (!absoluteUrl.startsWith(protocol.slice(0, 4))) {
      absoluteUrl = protocol.concat(absoluteUrl)
    }
    const response = await axios.post(baseUrl, { "url": absoluteUrl })
    setShortenedUrl(`${baseUrl}${response.data.hash}`)
  }

  return (
    <>
      <form onSubmit={shortenUrl}>
        <input value={url} onChange={(e) => setUrl(e.target.value)}/>
        <button type='submit'>Shorten</button>
      </form>
      <div>
        {
          shortenedUrl 
            ? <>
                <a href={shortenedUrl}>{shortenedUrl}</a>
                <button onClick={() => navigator.clipboard.writeText(shortenedUrl)}>copy</button>
              </>
            : null
        }
      </div>
    </>
  )
}

export default App
