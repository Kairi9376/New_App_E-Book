const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');

router.get('/', bookController.getAllBooks);
router.get('/:id', bookController.getBookById);
router.post('/', bookController.createBook);
router.put('/:id', bookController.updateBook);
router.put('/:id/status', bookController.updateBookStatus);
router.post('/:id/increment-readers', bookController.incrementReadersCount);
router.delete('/:id', bookController.deleteBook);

module.exports = router;
