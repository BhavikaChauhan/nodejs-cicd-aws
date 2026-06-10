const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint — used by CI/CD rollback logic
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Sample products API — mimics a real client app
const products = [
  { id: 1, name: 'Cloud Storage Plan', price: 9.99, category: 'cloud' },
  { id: 2, name: 'DevOps Monitoring Suite', price: 49.99, category: 'devops' },
  { id: 3, name: 'CI/CD Pipeline Setup', price: 199.99, category: 'devops' },
];

app.get('/', (req, res) => {
  res.json({
    message: 'Product API is running',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0'
  });
});

app.get('/api/products', (req, res) => {
  res.json({ success: true, count: products.length, data: products });
});

app.get('/api/products/:id', (req, res) => {
  const product = products.find(p => p.id === parseInt(req.params.id));
  if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
  res.json({ success: true, data: product });
});

app.listen(port, () => {
  console.log(`Server running on port ${port} [${process.env.NODE_ENV || 'development'}]`);
});

module.exports = app;
