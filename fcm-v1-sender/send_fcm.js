const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const serviceAccount = require('./service-account.json');

async function sendNotification() {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  const projectId = serviceAccount.project_id;
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const messagePayload = {
    message: {
      topic: 'all', // hoặc 'token': 'abc123'
      notification: {
        title: '🔥 Gửi từ NodeJS',
        body: 'Thông báo FCM HTTP v1 thành công!',
      },
    },
  };

  const response = await axios.post(url, messagePayload, {
    headers: {
      Authorization: `Bearer ${accessToken.token}`,
      'Content-Type': 'application/json',
    },
  });

  console.log('✅ Đã gửi thành công:', response.data);
}

sendNotification().catch((err) => {
  console.error('❌ Lỗi gửi FCM:', err.response?.data || err.message);
});
