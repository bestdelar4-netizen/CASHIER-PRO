import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashierPro());
}

// ============================================================
// APP
// ============================================================

class CashierPro extends StatelessWidget {
  const CashierPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CASHIER PRO',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const AppController(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Product {
  String id;
  String name;
  double buyPrice;
  double sellPrice;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
  });

  double get profit => sellPrice - buyPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'quantity': quantity,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      buyPrice: (json['buyPrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get total => product.sellPrice * quantity;
  double get profit => product.profit * quantity;
}

class Sale {
  String id;
  DateTime date;
  double total;
  double paid;
  double change;
  double profit;
  int items;

  Sale({
    required this.id,
    required this.date,
    required this.total,
    required this.paid,
    required this.change,
    required this.profit,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'total': total,
        'paid': paid,
        'change': change,
        'profit': profit,
        'items': items,
      };

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      total: (json['total'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      items: (json['items'] ?? 0).toInt(),
    );
  }
}

// ============================================================
// CONTROLLER
// ============================================================

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  int currentIndex = 0;

  List<Product> products = [];
  List<Sale> sales = [];

  bool darkMode = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final productsJson = prefs.getString('products');
    final salesJson = prefs.getString('sales');

    if (productsJson != null) {
      final data = jsonDecode(productsJson) as List;
      products = data
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (salesJson != null) {
      final data = jsonDecode(salesJson) as List;
      sales = data
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    darkMode = prefs.getBool('darkMode') ?? false;

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      'sales',
      jsonEncode(sales.map((e) => e.toJson()).toList()),
    );

    await prefs.setBool('darkMode', darkMode);
  }

  double get todaySales {
    final now = DateTime.now();

    return sales
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  double get todayProfit {
    final now = DateTime.now();

    return sales
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .fold(0.0, (sum, s) => sum + s.profit);
  }

  int get todayInvoices {
    final now = DateTime.now();

    return sales
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .length;
  }

  double get totalSales =>
      sales.fold(0.0, (sum, sale) => sum + sale.total);

  double get totalProfit =>
      sales.fold(0.0, (sum, sale) => sum + sale.profit);

  void addProduct(Product product) {
    setState(() => products.add(product));
    saveData();
  }

  void updateProduct() {
    setState(() {});
    saveData();
  }

  void deleteProduct(Product product) {
    setState(() => products.remove(product));
    saveData();
  }

  void completeSale(Sale sale) {
    setState(() => sales.add(sale));
    saveData();
  }

  void toggleDarkMode() {
    setState(() => darkMode = !darkMode);
    saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      DashboardPage(
        products: products,
        todaySales: todaySales,
        todayProfit: todayProfit,
        todayInvoices: todayInvoices,
        totalSales: totalSales,
        totalProfit: totalProfit,
      ),
      CashierPage(
        products: products,
        onSaleComplete: completeSale,
        onStockChanged: updateProduct,
      ),
      ProductsPage(
        products: products,
        onAdd: addProduct,
        onUpdate: updateProduct,
        onDelete: deleteProduct,
      ),
      ReportsPage(
        sales: sales,
      ),
      SettingsPage(
        darkMode: darkMode,
        onThemeChanged: toggleDarkMode,
      ),
    ];

    const titles = [
      'الرئيسية',
      'الكاشير',
      'المنتجات',
      'التقارير',
      'الإعدادات',
    ];

    return Theme(
      data: darkMode
          ? ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
            )
          : ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.light,
            ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              titles[currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: pages[currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() => currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'الكاشير',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'المنتجات',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'التقارير',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final List<Product> products;
  final double todaySales;
  final double todayProfit;
  final int todayInvoices;
  final double totalSales;
  final double totalProfit;

  const DashboardPage({
    super.key,
    required this.products,
    required this.todaySales,
    required this.todayProfit,
    required this.todayInvoices,
    required this.totalSales,
    required this.totalProfit,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((p) => p.quantity <= 5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'مرحبًا بك في CASHIER PRO 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width >= 800 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                title: 'مبيعات اليوم',
                value: '${todaySales.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'أرباح اليوم',
                value: '${todayProfit.toStringAsFixed(2)} ج',
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'فواتير اليوم',
                value: '$todayInvoices',
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: 'المنتجات',
                value: '${products.length}',
                icon: Icons.inventory,
              ),
            ],
          ),

          const SizedBox(height: 15),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('ملخص الحساب'),
                ),
                ListTile(
                  title: const Text('إجمالي المبيعات'),
                  trailing: Text(
                    '${totalSales.toStringAsFixed(2)} ج',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('إجمالي الأرباح'),
                  trailing: Text(
                    '${totalProfit.toStringAsFixed(2)} ج',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text('المخزون'),
              subtitle: Text(
                lowStock.isEmpty
                    ? 'المخزون جيد'
                    : '${lowStock.length} منتج منخفض المخزون',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CASHIER
// ============================================================

class CashierPage extends StatefulWidget {
  final List<Product> products;
  final Function(Sale) onSaleComplete;
  final VoidCallback onStockChanged;

  const CashierPage({
    super.key,
    required this.products,
    required this.onSaleComplete,
    required this.onStockChanged,
  });

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<CartItem> cart = [];
  String search = '';

  double get total =>
      cart.fold(0.0, (sum, item) => sum + item.total);

  double get profit =>
      cart.fold(0.0, (sum, item) => sum + item.profit);

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(context, 'المنتج غير متوفر');
      return;
    }

    final existing = cart.where(
      (item) => item.product.id == product.id,
    );

    if (existing.isNotEmpty) {
      final item = existing.first;

      if (item.quantity >= product.quantity) {
        showMessage(context, 'الكمية المتاحة انتهت');
        return;
      }

      setState(() => item.quantity++);
    } else {
      setState(() {
        cart.add(
          CartItem(
            product: product,
            quantity: 1,
          ),
        );
      });
    }
  }

  void decrease(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
    });
  }

  void increase(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      showMessage(context, 'لا توجد كمية إضافية');
      return;
    }

    setState(() => item.quantity++);
  }

  Future<void> checkout() async {
    if (cart.isEmpty) {
      showMessage(context, 'السلة فارغة');
      return;
    }

    final controller = TextEditingController(
      text: total.toStringAsFixed(2),
    );

    final paid = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإجمالي: ${total.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  suffixText: 'ج',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    double.tryParse(controller.text) ?? 0;
                Navigator.pop(context, value);
              },
              child: const Text('تأكيد البيع'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (paid == null) return;

    if (paid < total) {
      showMessage(context, 'المبلغ المدفوع أقل من الإجمالي');
      return;
    }

    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      total: total,
      paid: paid,
      change: paid - total,
      profit: profit,
      items: cart.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );

    for (final item in cart) {
      item.product.quantity -= item.quantity;
    }

    widget.onSaleComplete(sale);
    widget.onStockChanged();

    setState(() => cart.clear());

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تم البيع بنجاح ✅'),
          content: Text(
            'الإجمالي: ${sale.total.toStringAsFixed(2)} ج\n'
            'المدفوع: ${sale.paid.toStringAsFixed(2)} ج\n'
            'الباقي: ${sale.change.toStringAsFixed(2)} ج\n'
            'الربح: ${sale.profit.toStringAsFixed(2)} ج',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((product) {
      return product.name.toLowerCase().contains(
            search.toLowerCase(),
          );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) {
              setState(() => search = value);
            },
            decoration: const InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),

        Expanded(
          flex: 5,
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد منتجات',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 800
                            ? 4
                            : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => addToCart(product),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 34,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                product.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.sellPrice.toStringAsFixed(2)} ج',
                              ),
                              Text(
                                'المخزون: ${product.quantity}',
                                style: TextStyle(
                                  color: product.quantity <= 5
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        const Divider(height: 1),

        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child: Text('السلة فارغة'),
                      )
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];

                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text(
                              '${item.product.sellPrice.toStringAsFixed(2)} ج × ${item.quantity}',
                            ),
                            leading: IconButton(
                              onPressed: () => decrease(item),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => increase(item),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                  ),
                                ),
                                Text(
                                  '${item.total.toStringAsFixed(2)} ج',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الإجمالي: ${total.toStringAsFixed(2)} ج',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الربح: ${profit.toStringAsFixed(2)} ج',
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: checkout,
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('بيع'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PRODUCTS
// ============================================================

class ProductsPage extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onAdd;
  final VoidCallback onUpdate;
  final Function(Product) onDelete;

  const ProductsPage({
    super.key,
    required this.products,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String search = '';

  void productDialog({Product? product}) {
    final nameController =
        TextEditingController(text: product?.name ?? '');

    final buyController = TextEditingController(
      text: product == null ? '' : product.buyPrice.toString(),
    );

    final sellController = TextEditingController(
      text: product == null ? '' : product.sellPrice.toString(),
    );

    final quantityController = TextEditingController(
      text: product == null ? '' : product.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            product == null
                ? 'إضافة منتج'
                : 'تعديل المنتج',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: buyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء',
                    suffixText: 'ج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sellController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'سعر البيع',
                    suffixText: 'ج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final buy =
                    double.tryParse(buyController.text) ?? 0;
                final sell =
                    double.tryParse(sellController.text) ?? 0;
                final quantity =
                    int.tryParse(quantityController.text) ?? 0;

                if (name.isEmpty ||
                    buy < 0 ||
                    sell <= 0 ||
                    quantity < 0) {
                  showMessage(
                    context,
                    'أدخل بيانات صحيحة',
                  );
                  return;
                }

                if (product == null) {
                  widget.onAdd(
                    Product(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      buyPrice: buy,
                      sellPrice: sell,
                      quantity: quantity,
                    ),
                  );
                } else {
                  product.name = name;
                  product.buyPrice = buy;
                  product.sellPrice = sell;
                  product.quantity = quantity;
                  widget.onUpdate();
                }

                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text(
            'هل تريد حذف "${product.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                widget.onDelete(product);
                Navigator.pop(context);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      return p.name.toLowerCase().contains(
            search.toLowerCase(),
          );
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  setState(() => search = value);
                },
                decoration: const InputDecoration(
                  hintText: 'بحث في المنتجات...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد منتجات',
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        90,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.inventory_2),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'شراء: ${product.buyPrice.toStringAsFixed(2)} ج\n'
                              'بيع: ${product.sellPrice.toStringAsFixed(2)} ج\n'
                              'المخزون: ${product.quantity}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  productDialog(
                                    product: product,
                                  );
                                } else {
                                  deleteProduct(product);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 15,
          left: 15,
          child: FloatingActionButton.extended(
            onPressed: () => productDialog(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REPORTS
// ============================================================

class ReportsPage extends StatelessWidget {
  final List<Sale> sales;

  const ReportsPage({
    super.key,
    required this.sales,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        sales.fold(0.0, (sum, sale) => sum + sale.total);

    final profit =
        sales.fold(0.0, (sum, sale) => sum + sale.profit);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'المبيعات',
                  value: '${total.toStringAsFixed(2)} ج',
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'الأرباح',
                  value: '${profit.toStringAsFixed(2)} ج',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        Expanded(
          child: sales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد فواتير حتى الآن',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale =
                        sales[sales.length - 1 - index];

                    final number = sale.id.length > 6
                        ? sale.id.substring(
                            sale.id.length - 6,
                          )
                        : sale.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text('فاتورة #$number'),
                        subtitle: Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year}'
                          ' • ${sale.items} قطعة\n'
                          'الربح: ${sale.profit.toStringAsFixed(2)} ج',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${sale.total.toStringAsFixed(2)} ج',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onThemeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  Future<void> openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/201030415839',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      showMessage(context, 'تعذر فتح واتساب');
    }
  }

  Future<void> makeCall(BuildContext context) async {
    final uri = Uri.parse('tel:01012610087');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage(context, 'تعذر فتح الاتصال');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            secondary: Icon(
              darkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('الوضع الليلي'),
            subtitle: const Text('تغيير مظهر التطبيق'),
            value: darkMode,
            onChanged: (_) => onThemeChanged(),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'الدعم والشكاوى',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 55,
                ),
                const SizedBox(height: 10),
                const Text(
                  'الدعم والاستفسارات والشكاوى',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        openWhatsApp(context),
                    icon: const Icon(Icons.chat),
                    label: const Text(
                      'واتساب الشكاوى',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => makeCall(context),
                    icon: const Icon(Icons.phone),
                    label: const Text('اتصال مباشر'),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'واتساب: 01030415839\n'
                  'المكالمات: 01012610087',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('CASHIER PRO'),
            subtitle: Text('الإصدار V4.0'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

void showMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}