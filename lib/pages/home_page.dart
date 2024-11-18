import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sangy/pages/addbook_page1.dart';
import 'package:sangy/pages/chat_list_page.dart';
import 'package:sangy/pages/editbook_page.dart';
import 'package:sangy/pages/favourite_page.dart';
import 'package:sangy/pages/login_page.dart';
import 'package:sangy/pages/book_detail_page.dart';
import 'package:sangy/pages/mylisting_page.dart'; // Import the MyListingsPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final CollectionReference booksRef =
      FirebaseFirestore.instance.collection('books');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _addBook(String title, String imageUrl, String description,
      String price, String quantity) async {
    try {
      await booksRef.add({
        'title': title,
        'author': user.email,
        'userId': user.uid,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'description': description,
        'price': price,
        'quantity': quantity,
      });
    } catch (e) {
      print("Error adding book: $e");
    }
  }

  void _navigateToAddBookPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBookPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _addBook(
        result['title'],
        result['imageUrl'],
        result['description'],
        result['price'],
        result['quantity'],
      );
    }
  }

  Future<void> _deleteBook(String bookId) async {
    try {
      await booksRef.doc(bookId).delete();
    } catch (e) {
      print("Error deleting book: $e");
    }
  }

  void _navigateToEditBookPage(String bookId, String title, String imageUrl,
      String description, String price, String quantity) async {
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
      setState(() {}); // Update the book with new data
    }
  }

  void _navigateToBookDetailPage(String bookId, String title, String author,
      String imageUrl, String description, String price, String quantity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          bookId: bookId,
          title: title,
          author: author,
          imageUrl: imageUrl,
          description: description,
          price: price,
          quantity: quantity,
        ),
      ),
    );
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(224, 224, 224, 1),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatListPage()),
              );
            },
          ),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FavoritesPage()));
              },
              icon: Icon(Icons.favorite_outline))
        ],
        title: const Text(
          'BOOKSHELF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a book by name...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 4,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[900],
                    radius: 40,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.email ?? 'User',
                    style: TextStyle(color: Colors.grey[900], fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.list,
                color: Colors.grey[900],
              ),
              title: const Text('My Listings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyListingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.grey[900],
              ),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _logout();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: booksRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No books added yet!',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          // Filter the books based on the search query
          var filteredBooks = snapshot.data!.docs.where((bookDoc) {
            var book = bookDoc.data() as Map<String, dynamic>;
            var bookTitle = book['title'].toString().toLowerCase();
            return bookTitle.contains(_searchQuery);
          }).toList();

          return ListView(
            children: filteredBooks
                // Filter out books authored by the current user
                .where((bookDoc) {
              Map<String, dynamic> book =
                  bookDoc.data() as Map<String, dynamic>;
              return book['author'] != user.email;
            }).map((bookDoc) {
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
                          ],
                        ),
                      ),
                      // Removed the conditional widget for user books
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBookPage,
        backgroundColor: Colors.grey[900],
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
