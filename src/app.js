const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const port = process.env.PORT || 3000;

app.use(helmet());
app.use(rateLimit({ windowMs: 60 * 1000, max: 100, message: { success: false, error: 'Too many requests, slow down.' } }));
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.json({ message: 'Product API is running', environment: process.env.NODE_ENV || 'development', version: process.env.APP_VERSION || '1.0.0' });
});

const products = [
  { id: 1, name: 'Cloud Storage Plan', price: 9.99, category: 'cloud' },
  { id: 2, name: 'DevOps Monitoring Suite', price: 49.99, category: 'devops' },
  { id: 3, name: 'CI/CD Pipeline Setup', price: 199.99, category: 'devops' },
];

app.get('/api/products', (req, res) => {
  res.json({ success: true, count: products.length, data: products });
});

app.get('/api/products/:id', (req, res) => {
  const product = products.find(p => p.id === parseInt(req.params.id));
  if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
  res.json({ success: true, data: product });
});

app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.error(err.stack);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

const server = app.listen(port, () => {
  console.log(`Server running on port ${port} [${process.env.NODE_ENV || 'development'}]`);
});

module.exports = { app, server };
