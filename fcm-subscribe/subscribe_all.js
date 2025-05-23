const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

async function subscribeAllTokensToTopic() {
  const snapshot = await db.collection('users').get();
  const tokens = [];

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (Array.isArray(data.fcmTokens)) {
      tokens.push(...data.fcmTokens);
    }
  });

  if (tokens.length === 0) {
    console.log('❗ Không tìm thấy token nào trong Firestore.');
    return;
  }

  console.log(`📦 Đang subscribe ${tokens.length} token vào topic "all"...`);

  // Firebase chỉ cho tối đa 1000 tokens mỗi lần
  const chunkSize = 500;
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    try {
      const res = await messaging.subscribeToTopic(chunk, 'all');
      console.log(`✅ Subscribed ${chunk.length} tokens:`, res.successCount);
    } catch (err) {
      console.error('❌ Lỗi khi subscribe:', err.error || err.message);
    }
  }
}

subscribeAllTokensToTopic();
