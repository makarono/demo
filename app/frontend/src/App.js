import React, { useState } from 'react';

function App() {
  const [response, setResponse] = useState('');

  const handleGetClick = async () => {
    try {
      const res = await fetch(process.env.REACT_APP_BACKEND_ENDPOINT);
      const data = await res.json();
      setResponse(JSON.stringify(data));
    } catch (error) {
      console.error(error);
    }
  };

  const handlePostClick = async () => {
    try {
      const payload = {
        count: Math.floor(Date.now() / 1000),
      };

      const res = await fetch(process.env.REACT_APP_BACKEND_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const data = await res.json();
      setResponse(JSON.stringify(data));
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div>
      <button onClick={handleGetClick}>GET</button>
      <button onClick={handlePostClick}>POST</button>
      <div>
        <pre>{response}</pre>
      </div>
    </div>
  );
}

export default App;
