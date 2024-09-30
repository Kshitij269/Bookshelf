import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String author;
  final String description;
  final String price;
  final String quantity;
  final String bookId; // Add book ID to identify the book

  const BookDetailPage({
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.description,
    required this.price,
    required this.quantity,
    required this.bookId, // Add this parameter to identify the book
    super.key,
  });

  @override
  _BookDetailPageState createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus(); // Check the initial favorite status
  }

  Future<void> _checkFavoriteStatus() async {
    // Check if the book is already in the user's favorites
    DocumentSnapshot userFavoritesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('favorites')
        .doc(widget.bookId)
        .get();

    setState(() {
      isFavorite = userFavoritesSnapshot.exists;
    });
  }

  Future<void> _toggleFavoriteStatus() async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('favorites')
        .doc(widget.bookId);

    if (isFavorite) {
      // If already favorite, remove it
      await userFavoritesRef.delete();
    } else {
      // If not favorite, add it to the user's favorites collection
      await userFavoritesRef.set({
        'title': widget.title,
        'imageUrl': widget.imageUrl,
        'author': widget.author,
        'description': widget.description,
        'price': widget.price,
        'quantity': widget.quantity,
        'bookId': widget.bookId,
        'addedAt': Timestamp.now(),
      });
    }

    // Toggle the favorite status in the UI
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Book Description',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavoriteStatus,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            // Book Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Author
            Text(
              'Author: ${widget.author}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Price
            Text(
              'Price: \₹${widget.price}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            // Quantity
            Text(
              'Quantity: ${widget.quantity}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
