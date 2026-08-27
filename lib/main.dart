import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashierPro());
}

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
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Product {
  String id;
  String name;
  double price;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
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

  double get total => product.price * quantity;
}

class Sale {
  final String id;
  final DateTime date;
  final double total;
  final double paid;
  final double change;
  final int items;

  Sale({
    required this.id,
    required this.date,
    required this.total,
    required this.paid,
    required this.change,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'paid': paid,
      'change': change,
      'items': items,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      total: (json['total'] as num).toDouble(),
      paid: (json['paid'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      items: (json['items'] as num).toInt(),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  List<Product> products = [];
  List<Sale> sales = [];

  bool loading = true;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final productsData = prefs.getString('products');
    final salesData = prefs.getString('sales');

    if (productsData != null) {
      final list = jsonDecode(productsData) as List;
      products = list
          .map((item) => Product.fromJson(item))
          .toList();
    }

    if (salesData != null) {
      final list = jsonDecode(salesData) as List;
      sales = list
          .map((item) => Sale.fromJson(item))
          .toList();
    }

    darkMode = prefs.getBool('darkMode') ?? false;

    setState(() {
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(
        products.map((p) => p.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'sales',
      jsonEncode(
        sales.map((s) => s.toJson()).toList(),
      ),
    );

    await prefs.setBool('darkMode', darkMode);
  }

  double get todaySales {
    final now = DateTime.now();

    return sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold(0, (sum, sale) => sum + sale.total);
  }

  int get todayInvoices {
    final now = DateTime.now();

    return sales.where(
      (sale) =>
          sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day,
    ).length;
  }

  double get totalProfit {
    // في V3 نعتبر إجمالي المبيعات هو القيمة الحالية.
    // حساب تكلفة المنتج والأرباح الصافية سيكون في V4.
    return sales.fold(0, (sum, sale) => sum + sale.total);
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
      products.remove(product);
    });
    saveData();
  }

  void completeSale(Sale sale) {
    setState(() {
      sales.add(sale);
    });
    saveData();
  }

  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });
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
        sales: sales,
        todaySales: todaySales,
        todayInvoices: todayInvoices,
        totalProfit: totalProfit,
      ),
      CashierPage(
        products: products,
        onSaleComplete: completeSale,
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
        onThemeChanged: toggleTheme,
      ),
    ];

    const titles = [
      'الرئيسية',
      'الكاشير',
      'المنتجات',
      'التقارير',
      'الإعدادات',
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
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
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final List<Product> products;
  final List<Sale> sales;
  final double todaySales;
  final int todayInvoices;
  final double totalProfit;

  const DashboardPage({
    super.key,
    required this.products,
    required this.sales,
    required this.todaySales,
    required this.todayInvoices,
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                title: 'مبيعات اليوم',
                value: '${todaySales.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'فواتير اليوم',
                value: '$todayInvoices',
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: 'إجمالي المبيعات',
                value: '${totalProfit.toStringAsFixed(2)} ج',
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'المنتجات',
                value: '${products.length}',
                icon: Icons.inventory,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text('تنبيه المخزون'),
              subtitle: Text(
                lowStock.isEmpty
                    ? 'لا توجد منتجات منخفضة المخزون'
                    : '${lowStock.length} منتج يحتاج إلى المراجعة',
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
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
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

  const CashierPage({
    super.key,
    required this.products,
    required this.onSaleComplete,
  });

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<CartItem> cart = [];

  double get total {
    return cart.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(context, 'المنتج غير متوفر في المخزون');
      return;
    }

    final existing = cart.where(
      (item) => item.product.id == product.id,
    );

    if (existing.isNotEmpty) {
      final item = existing.first;

      if (item.quantity >= product.quantity) {
        showMessage(context, 'لا توجد كمية إضافية في المخزون');
        return;
      }

      setState(() {
        item.quantity++;
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

  void removeFromCart(CartItem item) {
    setState(() {
      cart.remove(item);
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
          content: TextField(
            controller: paidController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ المدفوع',
              suffixText: 'ج',
              border: OutlineInputBorder(),
            ),
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
              child: const Text('تأكيد'),
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

    final change = paid - total;

    for (final item in cart) {
      item.product.quantity -= item.quantity;
    }

    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      total: total,
      paid: paid,
      change: change,
      items: cart.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );

    widget.onSaleComplete(sale);

    setState(() {
      cart.clear();
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تمت عملية البيع ✅'),
          content: Text(
            'الإجمالي: ${sale.total.toStringAsFixed(2)} ج\n'
            'المدفوع: ${sale.paid.toStringAsFixed(2)} ج\n'
            'الباقي: ${sale.change.toStringAsFixed(2)} ج',
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
        Expanded(
          flex: 5,
          child: widget.products.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد منتجات\nأضف منتجات أولًا',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 700
                            ? 4
                            : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => addToCart(product),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag,
                                size: 35,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${product.price.toStringAsFixed(2)} ج',
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
          flex: 3,
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
                            leading: const Icon(
                              Icons.shopping_cart,
                            ),
                            title: Text(item.product.name),
                            subtitle: Text(
                              '${item.quantity} × '
                              '${item.product.price.toStringAsFixed(2)} ج',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.total.toStringAsFixed(2)} ج',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      removeFromCart(item),
                                  icon: const Icon(
                                    Icons.delete_outline,
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
                      child: Text(
                        'الإجمالي: ${total.toStringAsFixed(2)} ج',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
  void showProductDialog({Product? product}) {
    final nameController = TextEditingController(
      text: product?.name ?? '',
    );

    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );

    final quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '',
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
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
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
                final price =
                    double.tryParse(priceController.text) ?? 0;
                final quantity =
                    int.tryParse(quantityController.text) ?? 0;

                if (name.isEmpty || price <= 0 || quantity < 0) {
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
                      price: price,
                      quantity: quantity,
                    ),
                  );
                } else {
                  product.name = name;
                  product.price = price;
                  product.quantity = quantity;

                  widget.onUpdate(product);
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
      body: widget.products.isEmpty
          ? const Center(
              child: Text(
                'لا توجد منتجات\nاضغط "إضافة منتج" للبدء',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];

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
                      'السعر: ${product.price.toStringAsFixed(2)} ج\n'
                      'المخزون: ${product.quantity}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showProductDialog(product: product);
                        }

                        if (value == 'delete') {
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
    final total = sales.fold(
      0.0,
      (sum, sale) => sum + sale.total,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              leading: const Icon(
                Icons.analytics,
                size: 35,
              ),
              title: const Text('إجمالي المبيعات'),
              subtitle: Text(
                '${total.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const Divider(),

        Expanded(
          child: sales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مبيعات حتى الآن',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale =
                        sales[sales.length - 1 - index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt),
                        ),
                        title: Text(
                          'فاتورة #${sale.id.substring(sale.id.length > 6 ? sale.id.length - 6 : 0)}',
                        ),
                        subtitle: Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year}'
                          ' • ${sale.items} قطعة',
                        ),
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
      showMessage(
        context,
        'تعذر فتح واتساب',
      );
    }
  }

  Future<void> makeCall(BuildContext context) async {
    final uri = Uri.parse(
      'tel:01012610087',
    );

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
            subtitle: const Text(
              'تغيير مظهر التطبيق',
            ),
            value: darkMode,
            onChanged: (_) {
              onThemeChanged();
            },
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
                  size: 50,
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
                    label: const Text(
                      'واتساب الشكاوى',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        makeCall(context),
                    icon: const Icon(Icons.phone),
                    label: const Text(
                      'اتصال مباشر',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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
            subtitle: Text('الإصدار V3.0'),
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