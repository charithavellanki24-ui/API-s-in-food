import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FoodApiApp());
}

class FoodApiApp extends StatelessWidget {
  const FoodApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Explorer',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const FoodHomePage(),
    );
  }
}

class FoodHomePage extends StatefulWidget {
  const FoodHomePage({super.key});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  List<dynamic> meals = [];
  List<dynamic> filteredMeals = [];

  bool isLoading = false;
  String searchText = '';
  String selectedFood = 'chicken';

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFood('chicken');
  }

  Future<void> fetchFood(String food) async {
    if (food.trim().isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(food)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          meals = data['meals'] ?? [];
          filteredMeals = meals;
          selectedFood = food;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          meals = [];
          filteredMeals = [];
        });

        showMessage('Unable to load food data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        meals = [];
        filteredMeals = [];
      });

      showMessage('Internet connection error');
    }
  }

  void searchFood(String value) {
    searchText = value;

    if (value.trim().isEmpty) {
      setState(() {
        filteredMeals = meals;
      });
      return;
    }

    final search = value.toLowerCase();

    setState(() {
      filteredMeals = meals.where((meal) {
        final name =
            meal['strMeal']?.toString().toLowerCase() ?? '';

        final category =
            meal['strCategory']?.toString().toLowerCase() ?? '';

        final area =
            meal['strArea']?.toString().toLowerCase() ?? '';

        return name.contains(search) ||
            category.contains(search) ||
            area.contains(search);
      }).toList();
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3A1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void showFoodDetails(dynamic meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Image.network(
                    meal['strMealThumb'] ?? '',
                    height: 230,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        height: 230,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.restaurant,
                          size: 70,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['strMeal'] ?? 'Unknown Food',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A1C1C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildInfoChip(
                            Icons.category,
                            meal['strCategory'] ??
                                'Unknown',
                          ),
                          const SizedBox(width: 8),
                          buildInfoChip(
                            Icons.public,
                            meal['strArea'] ?? 'Unknown',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Cooking Instructions',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal['strInstructions'] ??
                            'Instructions not available.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fingerprint,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Meal ID: ${meal['idMeal']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFFE65100),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E342E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3A1C1C),
              Color(0xFF7B241C),
              Color(0xFFD35400),
              Color(0xFFFFA726),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(),
              buildSearchBar(),
              buildFoodButtons(),
              buildStatistics(),
              Expanded(
                child: isLoading
                    ? buildLoading()
                    : buildFoodTable(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          fetchFood(selectedFood);
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF7B241C),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Refresh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🍔',
                style: TextStyle(fontSize: 34),
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Food Explorer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Discover delicious meals using REST API',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        10,
      ),
      child: TextField(
        controller: searchController,
        onSubmitted: (value) {
          fetchFood(value);
        },
        onChanged: searchFood,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search food... e.g. pizza, pasta',
          hintStyle: const TextStyle(
            color: Colors.white70,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                fetchFood(searchController.text);
              }
            },
            icon: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.white,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFoodButtons() {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          buildFoodButton('🍗', 'Chicken'),
          buildFoodButton('🍕', 'Pizza'),
          buildFoodButton('🍝', 'Pasta'),
          buildFoodButton('🍔', 'Burger'),
          buildFoodButton('🥗', 'Salad'),
          buildFoodButton('🍰', 'Cake'),
        ],
      ),
    );
  }

  Widget buildFoodButton(
    String emoji,
    String name,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          searchController.text = name;
          fetchFood(name);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.17),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 5),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatistics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        8,
      ),
      child: Row(
        children: [
          buildStat(
            Icons.restaurant_menu,
            'Meals',
            meals.length.toString(),
          ),
          const SizedBox(width: 10),
          buildStat(
            Icons.search,
            'Results',
            filteredMeals.length.toString(),
          ),
          const SizedBox(width: 10),
          buildStat(
            Icons.public,
            'API',
            'LIVE',
          ),
        ],
      ),
    );
  }

  Widget buildStat(
    IconData icon,
    String title,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 15),
          Text(
            'Preparing delicious food...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFoodTable() {
    if (filteredMeals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🍽️',
              style: TextStyle(fontSize: 65),
            ),
            SizedBox(height: 10),
            Text(
              'No food found!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try another food name',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        75,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 58,
              dataRowMinHeight: 90,
              dataRowMaxHeight: 110,
              columnSpacing: 25,
              headingRowColor:
                  WidgetStateProperty.all(
                const Color(0xFF4E342E),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'PHOTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MEAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CATEGORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'AREA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MEAL ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: filteredMeals.map<DataRow>((meal) {
                return DataRow(
                  cells: [
                    DataCell(
                      GestureDetector(
                        onTap: () {
                          showFoodDetails(meal);
                        },
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(13),
                          child: Image.network(
                            meal['strMealThumb'] ?? '',
                            width: 75,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                width: 75,
                                height: 70,
                                color: Colors.orange.shade100,
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.orange,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      GestureDetector(
                        onTap: () {
                          showFoodDetails(meal);
                        },
                        child: SizedBox(
                          width: 220,
                          child: Text(
                            meal['strMeal'] ?? 'Unknown',
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: Text(
                          meal['strCategory'] ?? 'N/A',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        meal['strArea'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        meal['idMeal'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}