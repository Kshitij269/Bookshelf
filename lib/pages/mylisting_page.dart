import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sangy/pages/book_detail_page.dart';
import 'package:sangy/pages/editbook_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  _MyListingsPageState createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final CollectionReference booksRef =
      FirebaseFirestore.instance.collection('books');

  void _navigateToBookDetailPage(String bookId, String title, String author,
      String imageUrl, String description, String price, String quantity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          title: title,
          author: author,
          imageUrl: imageUrl,
          description: description,
          price: price,
          quantity: quantity,
          bookId: bookId,
        ),
      ),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    try {
      await booksRef.doc(bookId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting book: $e')),
      );
    }
  }

  void _navigateToEditBookPage(
    String bookId,
    String title,
    String imageUrl,
    String description,
    String price,
    String quantity,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookPage(
          bookId: bookId,
          initialTitle: title,
          initialImageUrl: imageUrl,
          initialDescription: description,
          initialPrice: price,
          initialQuantity: quantity,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {}); // Update the list with new data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(224, 224, 224, 1),
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
          'My Listings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: booksRef
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No books listed!',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((bookDoc) {
              Map<String, dynamic> book =
                  bookDoc.data() as Map<String, dynamic>;
              String bookId = bookDoc.id;

              return GestureDetector(
                onTap: () => _navigateToBookDetailPage(
                  bookId,
                  book['title'],
                  book['author'],
                  book['imageUrl'],
                  book['description'] ?? 'No description available',
                  book['price'] ?? 'N/A',
                  book['quantity'] ?? '0',
                ),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Display book image or default icon
                      book['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                book['imageUrl'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.book,
                              size: 80,
                            ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title'],
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 5),
                            Text('Added by: ${book['author']}'),
                            const SizedBox(height: 5),
                            Text('Price: \₹${book['price'] ?? 'N/A'}'),
                            Text('Quantity: ${book['quantity'] ?? '0'}'),
                            Text(
                                'Description: ${book['description'] ?? 'No description'}'),
                          ],
                        ),
                      ),
                      // Action buttons for editing and deleting
                      Container(
                        width: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                              onPressed: () {
                                _navigateToEditBookPage(
                                  bookId,
                                  book['title'],
                                  book['imageUrl'],
                                  book['description'] ?? '',
                                  book['price'] ?? '',
                                  book['quantity'] ?? '',
                                );
                              },
                            ),
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteBook(bookId);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
