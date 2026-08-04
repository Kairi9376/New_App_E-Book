const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');

router.get('/', bookController.getAllBooks);
router.get('/deleted', bookController.getDeletedBooks); // ต้องมาก่อน /:id
router.get('/:id', bookController.getBookById);
router.post('/', bookController.createBook);
router.put('/:id', bookController.updateBook);
router.put('/:id/restore', bookController.restoreBook);
router.post('/:id/increment-readers', bookController.incrementReadersCount);
router.delete('/:id', bookController.deleteBook);
router.delete('/:id/permanent', bookController.permanentDeleteBook);

module.exports = router;
