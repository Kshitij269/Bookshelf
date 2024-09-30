import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sangy/pages/book_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final User user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    // Assuming the favorites are stored in a subcollection of the user document
    final CollectionReference favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesRef.snapshots(), // Stream from the user's favorites
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error fetching favorites: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No favorites added!',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((favoriteDoc) {
              Map<String, dynamic> favorite =
                  favoriteDoc.data() as Map<String, dynamic>;
              String favoriteId = favoriteDoc.id;

              print('Favorite ID: $favoriteId, Data: $favorite'); // Debugging

              return GestureDetector(
                onTap: () => _navigateToBookDetailPage(
                  favoriteId,
                  favorite['title'],
                  favorite['author'],
                  favorite['imageUrl'],
                  favorite['description'] ?? 'No description available',
                  favorite['price'] ?? 'N/A',
                  favorite['quantity'] ?? '0',
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
                      favorite['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                favorite['imageUrl'],
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
                              favorite['title'],
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 5),
                            Text('Added by: ${favorite['author']}'),
                            const SizedBox(height: 5),
                            Text('Price: \$${favorite['price'] ?? 'N/A'}'),
                            Text('Quantity: ${favorite['quantity'] ?? '0'}'),
                            Text(
                              'Description: ${favorite['description'] ?? 'No description'}',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          _deleteFavorite(favoriteId);
                        },
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

  Future<void> _deleteFavorite(String favoriteId) async {
    try {
      // Adjusting the reference to the user's favorites
      final userFavoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(favoriteId);
      await userFavoritesRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing favorite: $e')),
      );
    }
  }
}
