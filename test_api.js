const axios = require('axios');

const PROJECT_URL = 'https://xculeusuctxdujcevnwv.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjdWxldXN1Y3R4ZHVqY2V2bnd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NTU3MTIsImV4cCI6MjA5NjMzMTcxMn0.Lga4Hoy7aJ-mjAOYH7dxWiQV4Yreu2_HpYFs6cFrDNY';

async function test() {
  try {
    const response = await axios.get(`${PROJECT_URL}/rest/v1/classes`, {
      headers: {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Accept-Profile': 'official'
      }
    });
    console.log('API success:', response.status, response.data);
  } catch (error) {
    console.error('API error:', error.response ? error.response.status : error.message, error.response ? error.response.data : '');
  }
}

test();
