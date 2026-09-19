import 'package:flutter/material.dart';

void main() {
  runApp(const KosharyApp());
}

class KosharyApp extends StatelessWidget {
  const KosharyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كشري أم سيف',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF111111),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int smallCount = 0;
  int largeCount = 0;

  double get total {
    return (smallCount * 15) + (largeCount * 20);
  }

  void addSmall() {
    setState(() {
      smallCount++;
    });
  }

  void addLarge() {
    setState(() {
      largeCount++;
    });
  }

  void resetSales() {
    setState(() {
      smallCount = 0;
      largeCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'كشري أم سيف',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // اللوجو
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'نقطة البيع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // الكشري الصغير
            _productCard(
              title: 'كشري صغير',
              price: 15,
              count: smallCount,
              icon: Icons.restaurant,
              onPressed: addSmall,
            ),

            const SizedBox(height: 12),

            // الكشري الكبير
            _productCard(
              title: 'كشري كبير',
              price: 20,
              count: largeCount,
              icon: Icons.restaurant_menu,
              onPressed: addLarge,
            ),

            const SizedBox(height: 25),

            // ملخص المبيعات
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ملخص المبيعات',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _summaryRow(
                    'الكشري الصغير',
                    '$smallCount طبق',
                  ),

                  _summaryRow(
                    'الكشري الكبير',
                    '$largeCount طبق',
                  ),

                  const Divider(
                    color: Colors.grey,
                  ),

                  _summaryRow(
                    'إجمالي الأطباق',
                    '${smallCount + largeCount