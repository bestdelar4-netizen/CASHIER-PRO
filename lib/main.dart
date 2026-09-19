import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = AppStore();
  await store.load();

  runApp(KosharyApp(store: store));
}

// ============================================================
// التطبيق
// ============================================================

class KosharyApp extends StatelessWidget {
  final AppStore store;

  const KosharyApp({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كشري أم سيف',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF111111),
        fontFamily: 'Arial',
        brightness: Brightness.dark,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MainPage(store: store),
      ),
    );
  }
}

// ============================================================
// الموديلات
// ============================================================

class Product {
  String id;
  String name;
  double salePrice;
  double buyPrice;
  double stock;
  double minimumStock;

  Product({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.buyPrice,
    required this.stock,
    required this.minimumStock,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'salePrice': salePrice,
      'buyPrice': buyPrice,
      'stock': stock,
      'minimumStock': minimumStock,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      salePrice: _toDouble(json['salePrice']),
      buyPrice: _toDouble(json['buyPrice']),
      stock: _toDouble(json['stock']),
      minimumStock: _toDouble(json['minimumStock']),
    );
  }
}

class Sale {
  String id;
  String productId;
  String productName;
  double quantity;
  double price;
  double total;
  DateTime date;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
      'date': date.toIso8601String(),
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      price: _toDouble(json['price']),
      total: _toDouble(json['total']),
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class Expense {
  String id;
  String name;
  double amount;
  String note;
  DateTime date;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      note: json['note']?.toString() ?? '',
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

// ============================================================
// التخزين
// ============================================================

class AppStore extends ChangeNotifier {
  static const String productsKey = 'koshary_products';
  static const String salesKey = 'koshary_sales';
  static const String expensesKey = 'koshary_expenses';

  final List<Product> products = [];
  final List<Sale> sales = [];
  final List<Expense> expenses = [];

  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final productsData = prefs.getString(productsKey);
      final salesData = prefs.getString(salesKey);
      final expensesData = prefs.getString(expensesKey);

      if (productsData != null && productsData.isNotEmpty) {
        final list = jsonDecode(productsData) as List;
        products.clear();
        products.addAll(
          list.map(
            (item) => Product.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }

      if (salesData != null && salesData.isNotEmpty) {
        final list = jsonDecode(salesData) as List;
        sales.clear();
        sales.addAll(
          list.map(
            (item) => Sale.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }

      if (expensesData != null && expensesData.isNotEmpty) {
        final list = jsonDecode(expensesData) as List;
        expenses.clear();
        expenses.addAll(
          list.map(
            (item) => Expense.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }
    } catch (_) {
      // لو البيانات القديمة فيها مشكلة لا يمنع تشغيل التطبيق.
    }

    if (products.isEmpty) {
      products.addAll([
        Product(
          id: 'small-koshary',
          name: 'كشري صغير',
          salePrice: 15,
          buyPrice: 8,
          stock: 0,
          minimumStock: 5,
        ),
        Product(
          id: 'large-koshary',
          name: 'كشري كبير',
          salePrice: 20,
          buyPrice: 11,
          stock: 0,
          minimumStock: 5,
        ),
      ]);

      await save();
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      productsKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      salesKey,
      jsonEncode(sales.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      expensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  Product? productById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct({
    required String name,
    required double salePrice,
    required double buyPrice,
    required double stock,
    required double minimumStock,
  }) async {
    products.add(
      Product(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        salePrice: salePrice,
        buyPrice: buyPrice,
        stock: stock,
        minimumStock: minimumStock,
      ),
    );

    await save();
    notifyListeners();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double salePrice,
    required double buyPrice,
    required double stock,
    required double minimumStock,
  }) async {
    final product = productById(id);

    if (product == null) return;

    product.name = name;
    product.salePrice = salePrice;
    product.buyPrice = buyPrice;
    product.stock = stock;
    product.minimumStock = minimumStock;

    await save();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    await save();
    notifyListeners();
  }

  Future<bool> addSale({
    required Product product,
    required double quantity,
  }) async {
    if (quantity <= 0) return false;

    if (product.stock < quantity) {
      return false;
    }

    product.stock -= quantity;

    sales.add(
      Sale(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        price: product.salePrice,
        total: product.salePrice * quantity,
        date: DateTime.now(),
      ),
    );

    await save();
    notifyListeners();

    return true;
  }

  Future<void> addExpense({
    required String name,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    expenses.add(
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        amount: amount,
        note: note,
        date: date,
      ),
    );

    await save();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
    await save();
    notifyListeners();
  }

  double get totalSales {
    return sales.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get totalExpenses {
    return expenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );
  }

  double get totalCostOfSoldProducts {
    double total = 0;

    for (final sale in sales) {
      final product = productById(sale.productId);

      if (product != null) {
        total += product.buyPrice * sale.quantity;
      }
    }

    return total;
  }

  double get estimatedProfit {
    return totalSales - totalCostOfSoldProducts - totalExpenses;
  }

  double get inventoryValue {
    return products.fold(
      0,
      (sum, product) => sum + (product.buyPrice * product.stock),
    );
  }

  List<Product> get lowStockProducts {
    return products
        .where(
          (product) => product.stock <= product.minimumStock,
        )
        .toList();
  }

  double salesToday() {
    final now = DateTime.now();

    return sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold(
          0,
          (sum, sale) => sum + sale.total,
        );
  }

  double expensesToday() {
    final now = DateTime.now();

    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day,
        )
        .fold(
          0,
          (sum, expense) => sum + expense.amount,
        );
  }

  Future<void> resetAllData() async {
    products.clear();
    sales.clear();
    expenses.clear();

    products.addAll([
      Product(
        id: 'small-koshary',
        name: 'كشري صغير',
        salePrice: 15,
        buyPrice: 8,
        stock: 0,
        minimumStock: 5,
      ),
      Product(
        id: 'large-koshary',
        name: 'كشري كبير',
        salePrice: 20,
        buyPrice: 11,
        stock: 0,
        minimumStock: 5,
      ),
    ]);

    await save();
    notifyListeners();
  }
}

// ============================================================
// الصفحة الرئيسية
// ============================================================

class MainPage extends StatefulWidget {
  final AppStore store;

  const MainPage({
    super.key,
    required this.store,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  final List<String> titles = [
    'الرئيسية',
    'المبيعات',
    'المخزون',
    'المصروفات',
    'التقارير',
  ];

  @override
  void initState() {
    super.initState();

    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        title: Text(
          'كشري أم سيف - ${titles[selectedIndex]}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (selectedIndex) {
      case 1:
        return SalesPage(store: widget.store);

      case 2:
        return InventoryPage(store: widget.store);

      case 3:
        return ExpensesPage(store: widget.store);

      case 4:
        return ReportsPage(store: widget.store);

      default:
        return DashboardPage(store: widget.store);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 130,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.restaurant,
                          size: 90,
                          color: Colors.amber,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'كشري أم سيف',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'نظام الكاشير والإدارة',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              icon: Icons.dashboard,
              title: 'الرئيسية',
              index: 0,
            ),
            _drawerItem(
              icon: Icons.point_of_sale,
              title: 'المبيعات',
              index: 1,
            ),
            _drawerItem(
              icon: Icons.inventory_2,
              title: 'المخزون والنواقص',
              index: 2,
            ),
            _drawerItem(
              icon: Icons.money_off,
              title: 'المصروفات',
              index: 3,
            ),
            _drawerItem(
              icon: Icons.bar_chart,
              title: 'التقارير',
              index: 4,
            ),
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
              ),
              title: const Text(
                'مسح كل البيانات',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              onTap: _resetAllData,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = selectedIndex == index;

    return ListTile(
      selected: selected,
      selectedTileColor: Colors.amber.withValues(alpha: 0.15),
      leading: Icon(
        icon,
        color: selected ? Colors.amber : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.amber : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        Navigator.pop(context);
      },
    );
  }

  Future<void> _resetAllData() async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('مسح البيانات'),
          content: const Text(
            'هل أنت متأكد أنك تريد مسح جميع المبيعات والمصروفات وإعادة المخزون؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('مسح'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.store.resetAllData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم مسح البيانات'),
        ),
      );
    }
  }
}

// ============================================================
// الرئيسية
// ============================================================

class DashboardPage extends StatelessWidget {
  final AppStore store;

  const DashboardPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.amber,
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: isWide ? 220 : 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      height: 180,
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.amber,
                        size: 100,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'لوحة التحكم',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.35 : 1.05,
                children: [
                  _statCard(
                    icon: Icons.today,
                    title: 'مبيعات اليوم',
                    value: '${_money(store.salesToday())} جنيه',
                  ),
                  _statCard(
                    icon: Icons.point_of_sale,
                    title: 'إجمالي المبيعات',
                    value: '${_money(store.totalSales)} جنيه',
                  ),
                  _statCard(
                    icon: Icons.money_off,
                    title: 'المصروفات',
                    value: '${_money(store.totalExpenses)} جنيه',
                  ),
                  _statCard(
                    icon: Icons.account_balance_wallet,
                    title: 'صافي الربح',
                    value: '${_money(store.estimatedProfit)} جنيه',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _lowStockCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Colors.amber,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.amber,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockCard() {
    final low = store.lowStockProducts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: low.isEmpty ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                low.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: low.isEmpty
                    ? Colors.greenAccent
                    : Colors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                low.isEmpty
                    ? 'المخزون جيد'
                    : 'نواقص المخزون',
                style: TextStyle(
                  color: low.isEmpty
                      ? Colors.greenAccent
                      : Colors.orange,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (low.isEmpty)
            const Text(
              'لا توجد أصناف وصلت للحد الأدنى.',
              style: TextStyle(
                color: Colors.white70,
              ),
            )
          else
            ...low.map(
              (product) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_money(product.stock)} متبقي',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// المبيعات
// ============================================================

class SalesPage extends StatefulWidget {
  final AppStore store;

  const SalesPage({
    super.key,
    required this.store,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  Product? selectedProduct;
  double quantity = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _salesHeader(),
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _salePanel()),
                    const SizedBox(width: 20),
                    Expanded(child: _todaySales()),
                  ],
                )
              else
                Column(
                  children: [
                    _salePanel(),
                    const SizedBox(height: 20),
                    _todaySales(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _salesHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.25),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.amber,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.point_of_sale,
            color: Colors.amber,
            size: 45,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل مبيعات',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'مبيعات اليوم: ${_money(widget.store.salesToday())} جنيه',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _salePanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بيع صنف',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<Product>(
            value: selectedProduct,
            decoration: const InputDecoration(
              labelText: 'اختار الصنف',
              border: OutlineInputBorder(),
            ),
            items: widget.store.products
                .map(
                  (product) => DropdownMenuItem<Product>(
                    value: product,
                    child: Text(
                      '${product.name} - ${_money(product.salePrice)} جنيه',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedProduct = value;
              });
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            initialValue: '1',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'الكمية',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              quantity = double.tryParse(value) ?? 1;
            },
          ),
          const SizedBox(height: 15),
          if (selectedProduct != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'السعر',
                    '${_money(selectedProduct!.salePrice)} جنيه',
                  ),
                  _infoRow(
                    'المتاح',
                    '${_money(selectedProduct!.stock)}',
                  ),
                  _infoRow(
                    'الإجمالي',
                    '${_money(selectedProduct!.salePrice * quantity)} جنيه',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _sell,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'تسجيل البيع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todaySales() {
    final today = DateTime.now();

    final list = widget.store.sales
        .where(
          (sale) =>
              sale.date.year == today.year &&
              sale.date.month == today.month &&
              sale.date.day == today.day,
        )
        .toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مبيعات اليوم',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                'لا توجد مبيعات اليوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            )
          else
            ...list.take(20).map(
              (sale) {
                return Card(
                  color: Colors.black,
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: Colors.greenAccent,
                    ),
                    title: Text(
                      sale.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${_money(sale.quantity)} × ${_money(sale.price)} جنيه',
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    trailing: Text(
                      '${_money(sale.total)} جنيه',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sell() async {
    if (selectedProduct == null) {
      _message('اختار الصنف الأول');
      return;
    }

    if (quantity <= 0) {
      _message('اكتب كمية صحيحة');
      return;
    }

    final success = await widget.store.addSale(
      product: selectedProduct!,
      quantity: quantity,
    );

    if (!success) {
      _message('الكمية غير متوفرة في المخزون');
      return;
    }

    setState(() {
      quantity = 1;
    });

    _message('تم تسجيل البيع بنجاح');
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================
// المخزون
// ============================================================

class InventoryPage extends StatefulWidget {
  final AppStore store;

  const InventoryPage({
    super.key,
    required this.store,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _inventoryHeader(),
              const SizedBox(height: 20),
              _summary(),
              const SizedBox(height: 20),
              ...widget.store.products.map(
                (product) => _productTile(product),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: isWide ? 400 : double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: () => _productDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'إضافة صنف جديد',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inventoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.inventory_2,
            color: Colors.amber,
            size: 45,
          ),
          SizedBox(width: 15),
          Text(
            'المخزون والنواقص',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final low = widget.store.lowStockProducts;

    return Row(
      children: [
        Expanded(
          child: _smallStat(
            'الأصناف',
            '${widget.store.products.length}',
            Colors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStat(
            'النواقص',
            '${low.length}',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStat(
            'قيمة المخزون',
            '${_money(widget.store.inventoryValue)}',
            Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _smallStat(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productTile(Product product) {
    final isLow = product.stock <= product.minimumStock;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isLow
              ? Colors.orange
              : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isLow
                  ? Colors.orange
                  : Colors.amber,
              child: Icon(
                Icons.restaurant,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'بيع: ${_money(product.salePrice)} جنيه',
                    style: const TextStyle(
                      color: Colors.amber,
                    ),
                  ),
                  Text(
                    'شراء: ${_money(product.buyPrice)} جنيه',
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    'المخزون: ${_money(product.stock)}',
                    style: TextStyle(
                      color: isLow
                          ? Colors.orange
                          : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الحد الأدنى: ${_money(product.minimumStock)}',
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'تعديل',
              onPressed: () => _productDialog(
                product: product,
              ),
              icon: const Icon(
                Icons.edit,
                color: Colors.amber,
              ),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: () => _deleteProduct(product),
              icon: const Icon(
                Icons.delete,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _productDialog({
    Product? product,
  }) async {
    final nameController = TextEditingController(
      text: product?.name ?? '',
    );

    final saleController = TextEditingController(
      text: product == null
          ? ''
          : _money(product.salePrice),
    );

    final buyController = TextEditingController(
      text: product == null
          ? ''
          : _money(product.buyPrice),
    );

    final stockController = TextEditingController(
      text: product == null
          ? ''
          : _money(product.stock),
    );

    final minimumController = TextEditingController(
      text: product == null
          ? '5'
          : _money(product.minimumStock),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            product == null
                ? 'إضافة صنف'
                : 'تعديل الصنف',
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _input(
                      controller: nameController,
                      label: 'اسم الصنف',
                      keyboardType: TextInputType.text,
                    ),
                    _input(
                      controller: saleController,
                      label: 'سعر البيع',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _input(
                      controller: buyController,
                      label: 'سعر الشراء',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _input(
                      controller: stockController,
                      label: 'الكمية الحالية',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _input(
                      controller: minimumController,
                      label: 'الحد الأدنى',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final sale = double.tryParse(saleController.text) ?? 0;
    final buy = double.tryParse(buyController.text) ?? 0;
    final stock = double.tryParse(stockController.text) ?? 0;
    final minimum =
        double.tryParse(minimumController.text) ?? 0;

    if (product == null) {
      await widget.store.addProduct(
        name: name,
        salePrice: sale,
        buyPrice: buy,
        stock: stock,
        minimumStock: minimum,
      );
    } else {
      await widget.store.updateProduct(
        id: product.id,
        name: name,
        salePrice: sale,
        buyPrice: buy,
        stock: stock,
        minimumStock: minimum,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'اكتب البيانات المطلوبة';
          }

          if (keyboardType != TextInputType.text) {
            final number = double.tryParse(value);

            if (number == null || number < 0) {
              return 'اكتب رقم صحيح';
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الصنف'),
          content: Text(
            'هل تريد حذف "${product.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.store.deleteProduct(product.id);
    }
  }
}

// ============================================================
// المصروفات
// ============================================================

class ExpensesPage extends StatefulWidget {
  final AppStore store;

  const ExpensesPage({
    super.key,
    required this.store,
  });

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    final expenses = [...widget.store.expenses]
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.redAccent,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.money_off,
                  color: Colors.redAccent,
                  size: 45,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المصروفات',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إجمالي المصروفات: ${_money(widget.store.totalExpenses)} جنيه',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton.icon(
              onPressed: _addExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                'إضافة مصروف',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty)
            _emptyExpenses()
          else
            ...expenses.map(
              (expense) => _expenseTile(expense),
            ),
        ],
      ),
    );
  }

  Widget _emptyExpenses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 65,
            color: Colors.white24,
          ),
          SizedBox(height: 10),
          Text(
            'لا توجد مصروفات مسجلة',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense expense) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.redAccent,
          child: Icon(
            Icons.money_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${_dateTime(expense.date)}'
          '${expense.note.isEmpty ? '' : ' - ${expense.note}'}',
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_money(expense.amount)} جنيه',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => _deleteExpense(expense),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExpenseDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة مصروف'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المصروف',
                      hintText: 'مثال: كهرباء',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'اكتب اسم المصروف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount =
                          double.tryParse(value ?? '');

                      if (amount == null || amount <= 0) {
                        return 'اكتب مبلغ صحيح';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await widget.store.addExpense(
      name: nameController.text.trim(),
      amount: double.parse(amountController.text),
      note: noteController.text.trim(),
      date: DateTime.now(),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المصروف'),
          content: const Text(
            'هل تريد حذف هذا المصروف؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.store.deleteExpense(expense.id);
    }
  }
}

// ============================================================
// التقارير
// ============================================================

class ReportsPage extends StatelessWidget {
  final AppStore store;

  const ReportsPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final todaySales = store.salesToday();
    final todayExpenses = store.expensesToday();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blueAccent,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: Colors.blueAccent,
                      size: 45,
                    ),
                    SizedBox(width: 15),
                    Text(
                      'التقارير والحسابات',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    isWide ? 1.4 : 1.05,
                children: [
                  _reportCard(
                    'مبيعات اليوم',
                    '${_money(todaySales)} جنيه',
                    Icons.today,
                    Colors.greenAccent,
                  ),
                  _reportCard(
                    'مصروفات اليوم',
                    '${_money(todayExpenses)} جنيه',
                    Icons.money_off,
                    Colors.redAccent,
                  ),
                  _reportCard(
                    'إجمالي المبيعات',
                    '${_money(store.totalSales)} جنيه',
                    Icons.point_of_sale,
                    Colors.amber,
                  ),
                  _reportCard(
                    'إجمالي المصروفات',
                    '${_money(store.totalExpenses)} جنيه',
                    Icons.receipt_long,
                    Colors.orange,
                  ),
                  _reportCard(
                    'تكلفة البضاعة المباعة',
                    '${_money(store.totalCostOfSoldProducts)} جنيه',
                    Icons.shopping_cart,
                    Colors.purpleAccent,
                  ),
                  _reportCard(
                    'صافي الربح',
                    '${_money(store.estimatedProfit)} جنيه',
                    Icons.account_balance_wallet,
                    Colors.cyanAccent,
                  ),
                  _reportCard(
                    'قيمة المخزون',
                    '${_money(store.inventoryValue)} جنيه',
                    Icons.inventory_2,
                    Colors.blueAccent,
                  ),
                  _reportCard(
                    'عدد عمليات البيع',
                    '${store.sales.length}',
                    Icons.receipt,
                    Colors.pinkAccent,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _salesByProduct(),
              const SizedBox(height: 20),
              _expenseSummary(),
            ],
          ),
        );
      },
    );
  }

  Widget _reportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color,
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 35,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _salesByProduct() {
    final Map<String, double> totals = {};

    for (final sale in store.sales) {
      totals[sale.productName] =
          (totals[sale.productName] ?? 0) + sale.total;
    }

    final entries = totals.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Container(
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
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'المبيعات حسب الصنف',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (entries.isEmpty)
            const Text(
              'لا توجد بيانات مبيعات',
              style: TextStyle(
                color: Colors.white54,
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${_money(entry.value)} جنيه',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _expenseSummary() {
    final Map<String, double> totals = {};

    for (final expense in store.expenses) {
      totals[expense.name] =
          (totals[expense.name] ?? 0) + expense.amount;
    }

    final entries = totals.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.redAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'المصروفات حسب النوع',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (entries.isEmpty)
            const Text(
              'لا توجد مصروفات',
              style: TextStyle(
                color: Colors.white54,
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${_money(entry.value)} جنيه',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// أدوات عامة
// ============================================================

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _dateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/$year - $hour:$minute';
}