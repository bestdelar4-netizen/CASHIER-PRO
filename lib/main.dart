import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashierPro());
}

// ============================================================
// APP
// ============================================================

class CashierPro extends StatefulWidget {
  const CashierPro({super.key});

  @override
  State<CashierPro> createState() => _CashierProState();
}

class _CashierProState extends State<CashierPro> {
  ThemeMode themeMode = ThemeMode.light;

  void changeTheme(bool dark) {
    setState(() {
      themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CASHIER PRO',
      themeMode: themeMode,
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
      home: HomeScreen(
        darkMode: themeMode == ThemeMode.dark,
        onThemeChanged: changeTheme,
      ),
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
  int lowStock;

  Product({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    this.lowStock = 5,
  });

  double get profit => sellPrice - buyPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'quantity': quantity,
        'lowStock': lowStock,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      buyPrice: (json['buyPrice'] ?? json['price'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      lowStock: (json['lowStock'] ?? 5).toInt(),
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
  final String id;
  final DateTime date;
  final double total;
  final double paid;
  final double change;
  final double profit;
  final int items;

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
      date: DateTime.parse(json['date'].toString()),
      total: (json['total'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      items: (json['items'] ?? 0).toInt(),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  List<Product> products = [];
  List<Sale> sales = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final productsData = prefs.getString('products_v5');

      if (productsData != null) {
        final decoded = jsonDecode(productsData) as List;
        products = decoded
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // قراءة بيانات النسخة القديمة إن وجدت
        final oldData = prefs.getString('products');

        if (oldData != null) {
          final decoded = jsonDecode(oldData) as List;
          products = decoded
              .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }

      final salesData = prefs.getString('sales_v5');

      if (salesData != null) {
        final decoded = jsonDecode(salesData) as List;
        sales = decoded
            .map((e) => Sale.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        final oldSales = prefs.getString('sales');

        if (oldSales != null) {
          final decoded = jsonDecode(oldSales) as List;
          sales = decoded
              .map((e) => Sale.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {
      products = [];
      sales = [];
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products_v5',
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );

    await prefs.setString(
      'sales_v5',
      jsonEncode(sales.map((s) => s.toJson()).toList()),
    );
  }

  double get totalSales {
    return sales.fold(0, (sum, sale) => sum + sale.total);
  }

  double get totalProfit {
    return sales.fold(0, (sum, sale) => sum + sale.profit);
  }

  double get todaySales {
    final now = DateTime.now();

    return sales
        .where(
          (s) =>
              s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day,
        )
        .fold(0, (sum, sale) => sum + sale.total);
  }

  double get todayProfit {
    final now = DateTime.now();

    return sales
        .where(
          (s) =>
              s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day,
        )
        .fold(0, (sum, sale) => sum + sale.profit);
  }

  int get todayInvoices {
    final now = DateTime.now();

    return sales.where(
      (s) =>
          s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day,
    ).length;
  }

  void addProduct(Product product) {
    setState(() {
      products.add(product);
    });
    saveData();
  }

  void updateProduct(Product product) {
    setState(() {});
    saveData();
  }

  void deleteProduct(Product product) {
    setState(() {
      products.removeWhere((p) => p.id == product.id);
    });
    saveData();
  }

  void completeSale(Sale sale) {
    setState(() {
      sales.add(sale);
    });
    saveData();
  }

  Future<void> saveAfterStockChange() async {
    await saveData();
    if (mounted) setState(() {});
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
        onStockChanged: saveAfterStockChange,
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
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    const titles = [
      'الرئيسية',
      'الكاشير',
      'المنتجات',
      'التقارير',
      'الإعدادات',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            titles[currentIndex],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: pages[currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
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
    final lowStock =
        products.where((p) => p.quantity <= p.lowStock).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'مرحبًا بك في CASHIER PRO 👋',
              style: TextStyle(
                fontSize: 23,
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
                value: money(todaySales),
                icon: Icons.payments,
              ),
              StatCard(
                title: 'أرباح اليوم',
                value: money(todayProfit),
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
            child: ListTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text(
                'حالة المخزون',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lowStock.isEmpty
                    ? 'المخزون جيد ولا توجد منتجات منخفضة'
                    : '${lowStock.length} منتج منخفض المخزون',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'ملخص المبيعات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  summaryRow('إجمالي المبيعات', totalSales),
                  summaryRow('إجمالي الأرباح', totalProfit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            money(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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
            Icon(icon, size: 30),
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
  final Future<void> Function() onStockChanged;

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
      cart.fold(0, (sum, item) => sum + item.total);

  double get profit =>
      cart.fold(0, (sum, item) => sum + item.profit);

  List<Product> get filteredProducts {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.products;
    }

    return widget.products
        .where(
          (p) => p.name.toLowerCase().contains(query),
        )
        .toList();
  }

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(context, 'المنتج غير متوفر');
      return;
    }

    CartItem? existing;

    for (final item in cart) {
      if (item.product.id == product.id) {
        existing = item;
        break;
      }
    }

    if (existing != null) {
      if (existing.quantity >= product.quantity) {
        showMessage(context, 'الكمية المطلوبة غير متوفرة');
        return;
      }

      setState(() {
        existing!.quantity++;
      });
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

  void increase(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      showMessage(context, 'لا توجد كمية إضافية');
      return;
    }

    setState(() {
      item.quantity++;
    });
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

  Future<void> checkout() async {
    if (cart.isEmpty) {
      showMessage(context, 'السلة فارغة');
      return;
    }

    final paidController = TextEditingController(
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
                'الإجمالي: ${money(total)}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: paidController,
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
                    double.tryParse(paidController.text) ?? 0;

                Navigator.pop(context, value);
              },
              child: const Text('تأكيد البيع'),
            ),
          ],
        );
      },
    );

    paidController.dispose();

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

      if (item.product.quantity < 0) {
        item.product.quantity = 0;
      }
    }

    widget.onSaleComplete(sale);
    await widget.onStockChanged();

    if (!mounted) return;

    setState(() {
      cart.clear();
    });

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تم البيع بنجاح ✅'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم الفاتورة: #${sale.id.substring(sale.id.length - 6)}'),
              const SizedBox(height: 8),
              Text('الإجمالي: ${money(sale.total)}'),
              Text('المدفوع: ${money(sale.paid)}'),
              Text('الباقي: ${money(sale.change)}'),
              Text('الربح: ${money(sale.profit)}'),
            ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
          child: TextField(
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          search = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        Expanded(
          flex: 5,
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد منتجات',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 800
                            ? 4
                            : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => addToCart(product),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag,
                                size: 34,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(money(product.sellPrice)),
                              Text(
                                'المخزون: ${product.quantity}',
                                style: TextStyle(
                                  color: product.quantity <=
                                          product.lowStock
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
                            leading: CircleAvatar(
                              child: Text('${item.quantity}'),
                            ),
                            title: Text(item.product.name),
                            subtitle: Text(
                              '${money(item.product.sellPrice)} × ${item.quantity}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      decrease(item),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      increase(item),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الإجمالي: ${money(total)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الربح: ${money(profit)}',
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: checkout,
                      icon: const Icon(Icons.receipt_long),
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
  final Function(Product) onUpdate;
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

  List<Product> get filteredProducts {
    final q = search.trim().toLowerCase();

    if (q.isEmpty) return widget.products;

    return widget.products
        .where(
          (p) => p.name.toLowerCase().contains(q),
        )
        .toList();
  }

  void showProductDialog({Product? product}) {
    final nameController =
        TextEditingController(text: product?.name ?? '');

    final buyController = TextEditingController(
      text: product?.buyPrice.toString() ?? '',
    );

    final sellController = TextEditingController(
      text: product?.sellPrice.toString() ?? '',
    );

    final quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '',
    );

    final lowStockController = TextEditingController(
      text: product?.lowStock.toString() ?? '5',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            product == null ? 'إضافة منتج' : 'تعديل المنتج',
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

                const SizedBox(height: 12),

                TextField(
                  controller: lowStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'حد التنبيه للمخزون',
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

                final lowStock =
                    int.tryParse(lowStockController.text) ?? 5;

                if (name.isEmpty ||
                    buy < 0 ||
                    sell <= 0 ||
                    quantity < 0 ||
                    lowStock < 0) {
                  showMessage(
                    context,
                    'أدخل بيانات صحيحة',
                  );
                  return;
                }

                if (sell < buy) {
                  showMessage(
                    context,
                    'سعر البيع أقل من سعر الشراء',
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
                      lowStock: lowStock,
                    ),
                  );
                } else {
                  product.name = name;
                  product.buyPrice = buy;
                  product.sellPrice = sell;
                  product.quantity = quantity;
                  product.lowStock = lowStock;

                  widget.onUpdate(product);
                }

                Navigator.pop(context);

                setState(() {});
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void confirmDelete(Product product) {
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
                setState(() {});
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
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'البحث عن منتج...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            Expanded(
              child: filteredProducts.isEmpty
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
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product =
                            filteredProducts[index];

                        final low =
                            product.quantity <= product.lowStock;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                low
                                    ? Icons.warning
                                    : Icons.inventory_2,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'شراء: ${money(product.buyPrice)}\n'
                              'بيع: ${money(product.sellPrice)}\n'
                              'المخزون: ${product.quantity} '
                              '${low ? '⚠️' : ''}',
                            ),
                            isThreeLine: true,
                            trailing:
                                PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showProductDialog(
                                    product: product,
                                  );
                                } else if (value == 'delete') {
                                  confirmDelete(product);
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
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => showProductDialog(),
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
    final totalSales =
        sales.fold(0.0, (sum, sale) => sum + sale.total);

    final totalProfit =
        sales.fold(0.0, (sum, sale) => sum + sale.profit);

    final totalItems =
        sales.fold(0, (sum, sale) => sum + sale.items);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width >= 700
                    ? 3
                    : 1,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3,
            children: [
              StatCard(
                title: 'إجمالي المبيعات',
                value: money(totalSales),
                icon: Icons.payments,
              ),
              StatCard(
                title: 'إجمالي الأرباح',
                value: money(totalProfit),
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'إجمالي القطع',
                value: '$totalItems',
                icon: Icons.shopping_cart,
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
                  padding: const EdgeInsets.all(12),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale =
                        sales[sales.length - 1 - index];

                    final invoiceId =
                        sale.id.length > 6
                            ? sale.id.substring(
                                sale.id.length - 6,
                              )
                            : sale.id;

                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(
                          'فاتورة #$invoiceId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year}'
                          ' • ${sale.items} قطعة',
                        ),
                        trailing: Text(
                          money(sale.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: const Text('الإجمالي'),
                            trailing:
                                Text(money(sale.total)),
                          ),
                          ListTile(
                            title: const Text('المدفوع'),
                            trailing:
                                Text(money(sale.paid)),
                          ),
                          ListTile(
                            title: const Text('الباقي'),
                            trailing:
                                Text(money(sale.change)),
                          ),
                          ListTile(
                            title: const Text('الربح'),
                            trailing:
                                Text(money(sale.profit)),
                          ),
                        ],
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
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  Future<void> openWhatsApp(BuildContext context) async {
    final uri =
        Uri.parse('https://wa.me/201030415839');

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      showMessage(
        context,
        'تعذر فتح واتساب',
      );
    }
  }

  Future<void> makeCall(BuildContext context) async {
    final uri = Uri.parse('tel:01012610087');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage(
        context,
        'تعذر فتح تطبيق الاتصال',
      );
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
            subtitle:
                const Text('تغيير مظهر البرنامج'),
            value: darkMode,
            onChanged: onThemeChanged,
          ),
        ),

        const SizedBox(height: 15),

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
                  'للدعم والاستفسارات والشكاوى',
                  textAlign: TextAlign.center,
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
                    label:
                        const Text('واتساب الشكاوى'),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        makeCall(context),
                    icon: const Icon(Icons.phone),
                    label:
                        const Text('اتصال مباشر'),
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

        const SizedBox(height: 15),

        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('CASHIER PRO'),
            subtitle: Text('الإصدار V5.0'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String money(double value) {
  return '${value.toStringAsFixed(2)} ج';
}

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