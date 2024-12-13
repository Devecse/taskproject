import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_application/screens/login_screen.dart';
import 'dart:convert';
import 'dart:io';

import 'addProduct_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> allProducts =
      []; // Master list of all the products.
  List<Map<String, dynamic>> products = []; // UI list .
  final TextEditingController searchController =
      TextEditingController(); // Controller for the search box
  final FocusNode searchFocusNode = FocusNode(); // Focus node for search box

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  //method to load all products
  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsString = prefs.getString('products');
    if (productsString != null) {
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(
          json.decode(productsString),
        );
        products = List.from(
            allProducts); // Initialize the filtered list from allproducts's list.
      });
    }
  }

  //method to save products in the shared preference
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(allProducts));
  }

  //navigates to the addproductpage and after returning checks for product duplicacy
  //,and then add the product to the master list and also saves it to the shared preference.
  Future<void> _addProduct() async {
    final newProduct = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage()),
    );

    if (newProduct != null) {
      // Check if product with the same name already exists
      bool isDuplicate = allProducts.any((product) =>
          product['name'].toLowerCase() == newProduct['name'].toLowerCase());

      if (isDuplicate) {
        // If duplicate, error message is shown.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product Already exists!"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // If no duplicate, add the new product to both lists
        setState(() {
          allProducts.add(newProduct);
          products = List.from(allProducts); // Update UI with the new product
        });
        _saveProducts();
      }
    }
  }

//deletes the product from the master list as well as the filtered or ui list.
  void _deleteProduct(int index) {
    setState(() {
      final productToRemove = products[index];
      allProducts.remove(productToRemove); // Remove from master list
      products.removeAt(index); // Remove from UI list
    });
    _saveProducts();
  }

  //this method filters the master list based on the search query.
  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        products = List.from(allProducts); // Reset UI list to master list
      });
    } else {
      setState(() {
        products = allProducts
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Unfocus when tapping outside
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 231, 238, 231),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 37, 47, 238),
          title: const Text(
            "Homepage",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                      'isLoggedIn', false); // Set logged out state

                  // Navigate to LoginScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.amber,
                ))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                focusNode: searchFocusNode, // Attach focus node
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _searchProducts, // Handle search
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: Text(
                        'No Product Found',
                        style: TextStyle(fontSize: 20),
                      ))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 3 / 4,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Stack(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(12.0),
                                        ),
                                        child: product['image'] != null
                                            ? Image.file(
                                                File(product['image']),
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.image_not_supported),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            '₹${product['price']}',
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 2,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteProduct(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await _addProduct();
            searchFocusNode
                .unfocus(); // Ensure search box is unfocused after returning
          },
          backgroundColor: const Color.fromARGB(255, 37, 47, 238),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}
