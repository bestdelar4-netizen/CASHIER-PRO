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
    return const CashierApp();
  }
}

class CashierApp extends StatefulWidget {
  const CashierApp({super.key});

  @override
  State<CashierApp> createState() => _CashierAppState();
}

class _CashierAppState extends State<CashierApp> {
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      darkMode = !darkMode;
    });

    await prefs.setBool('darkMode', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CASHIER PRO',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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
        darkMode: darkMode,
        onThemeChanged: toggleTheme,
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
  String category;
  double buyPrice;
  double sellPrice;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? 'عام',
      buyPrice: (json['buyPrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
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
}

class Sale {
  String id;
  DateTime date;
  double subtotal;
  double discount;
  double total;
  double paid;
  double change;
  int items;

  Sale({
    required this.id,
    required this.date,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    required this.change,
    required this.items,
  });

  double get profit => total;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
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
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      items: (json['items'] ?? 0).toInt(),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onThemeChanged;

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

    final productsString = prefs.getString('products');
    final salesString = prefs.getString('sales');

    if (productsString != null) {
      final data = jsonDecode(productsString) as List;

      products = data
          .map((e) => Product.fromJson(e))
          .toList();
    }

    if (salesString != null) {
      final data = jsonDecode(salesString) as List;

      sales = data
          .map((e) => Sale.fromJson(e))
          .toList();
    }

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
        .fold(0, (sum, s) => sum + s.total);
  }

  int get todayInvoices {
    final now = DateTime.now();

    return sales
        .where(
          (s) =>
              s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day,
        )
        .length;
  }

  double get totalProfit {
    double profit = 0;

    for (final sale in sales) {
      profit += sale.total;
    }

    return profit;
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
        onInventoryChanged: () {
          setState(() {});
          saveData();
        },
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
    final lowStock =
        products.where((p) => p.quantity <= 5).toList();

    final totalStockValue = products.fold(
      0.0,
      (sum, p) => sum + (p.buyPrice * p.quantity),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(
                      Icons.point_of_sale,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CASHIER PRO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'نظام إدارة المبيعات والمخزون',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 700
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                title: 'مبيعات اليوم',
                value:
                    '${todaySales.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'فواتير اليوم',
                value: '$todayInvoices',
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: 'إجمالي المبيعات',
                value:
                    '${totalProfit.toStringAsFixed(2)} ج',
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'عدد المنتجات',
                value: '${products.length}',
                icon: Icons.inventory,
              ),
            ],
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('قيمة المخزون'),
              trailing: Text(
                '${totalStockValue.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text('حالة المخزون'),
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
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
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
  final VoidCallback onInventoryChanged;

  const CashierPage({
    super.key,
    required this.products,
    required this.onSaleComplete,
    required this.onInventoryChanged,
  });

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<CartItem> cart = [];

  final searchController = TextEditingController();

  String search = '';

  double discount = 0;

  double get subtotal {
    return cart.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get total {
    final value = subtotal - discount;
    return value < 0 ? 0 : value;
  }

  List<Product> get filteredProducts {
    if (search.trim().isEmpty) {
      return widget.products;
    }

    return widget.products.where((p) {
      return p.name
              .toLowerCase()
              .contains(search.toLowerCase()) ||
          p.category
              .toLowerCase()
              .contains(search.toLowerCase());
    }).toList();
  }

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(
        context,
        'المنتج غير متوفر',
      );
      return;
    }

    final matches = cart.where(
      (item) => item.product.id == product.id,
    );

    if (matches.isNotEmpty) {
      final item = matches.first;

      if (item.quantity >= product.quantity) {
        showMessage(
          context,
          'لا توجد كمية إضافية',
        );
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

  void increase(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      showMessage(
        context,
        'لا توجد كمية إضافية في المخزون',
      );
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

  Future<void> showDiscountDialog() async {
    final controller = TextEditingController(
      text: discount.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('خصم على الفاتورة'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'قيمة الخصم',
              suffixText: 'ج',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    double.tryParse(controller.text) ??
                        0;

                Navigator.pop(context, value);
              },
              child: const Text('تطبيق'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null) return;

    setState(() {
      discount =
          value.clamp(0, subtotal).toDouble();
    });
  }

  Future<void> checkout() async {
    if (cart.isEmpty) {
      showMessage(
        context,
        'السلة فارغة',
      );
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
                'الإجمالي: ${total.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: paidController,
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
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    double.tryParse(
                          paidController.text,
                        ) ??
                        0;

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
      showMessage(
        context,
        'المبلغ المدفوع أقل من الإجمالي',
      );
      return;
    }

    final change = paid - total;

    for (final item in cart) {
      item.product.quantity -= item.quantity;
    }

    final sale = Sale(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      date: DateTime.now(),
      subtotal: subtotal,
      discount: discount,
      total: total,
      paid: paid,
      change: change,
      items: cart.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );

    widget.onSaleComplete(sale);

    widget.onInventoryChanged();

    setState(() {
      cart.clear();
      discount = 0;
    });

    if (!mounted) return;

    showInvoice(sale);
  }

  void showInvoice(Sale sale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle),
              SizedBox(width: 8),
              Text('تم البيع بنجاح'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text('رقم الفاتورة: ${sale.id}'),
              const Divider(),
              Text(
                'الإجمالي قبل الخصم: '
                '${sale.subtotal.toStringAsFixed(2)} ج',
              ),
              Text(
                'الخصم: '
                '${sale.discount.toStringAsFixed(2)} ج',
              ),
              Text(
                'الإجمالي: '
                '${sale.total.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'المدفوع: '
                '${sale.paid.toStringAsFixed(2)} ج',
              ),
              Text(
                'الباقي: '
                '${sale.change.toStringAsFixed(2)} ج',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context),
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
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon:
                  const Icon(Icons.search),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();

                        setState(() {
                          search = '';
                        });
                      },
                      icon:
                          const Icon(Icons.clear),
                    ),
              border:
                  const OutlineInputBorder(),
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
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context)
                                    .size
                                    .width >
                                700
                            ? 4
                            : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount:
                      filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product =
                        filteredProducts[index];

                    return Card(
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap: () =>
                            addToCart(product),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            10,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons.shopping_bag,
                                size: 32,
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                product.name,
                                textAlign:
                                    TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow
                                    .ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                '${product.sellPrice.toStringAsFixed(2)} ج',
                              ),
                              Text(
                                'المخزون: ${product.quantity}',
                                style: TextStyle(
                                  color:
                                      product.quantity <=
                                              5
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
                        child:
                            Text('السلة فارغة'),
                      )
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder:
                            (context, index) {
                          final item =
                              cart[index];

                          return ListTile(
                            leading:
                                const Icon(
                              Icons.shopping_cart,
                            ),
                            title: Text(
                              item.product.name,
                            ),
                            subtitle: Text(
                              '${item.product.sellPrice.toStringAsFixed(2)} ج × ${item.quantity}',
                            ),
                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      decrease(item),
                                  icon: const Icon(
                                    Icons.remove,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      increase(item),
                                  icon: const Icon(
                                    Icons.add,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding:
                    const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'المجموع: '
                            '${subtotal.toStringAsFixed(2)} ج',
                          ),
                        ),
                        Text(
                          'خصم: '
                          '${discount.toStringAsFixed(2)} ج',
                        ),
                        IconButton(
                          onPressed:
                              showDiscountDialog,
                          icon: const Icon(
                            Icons.discount,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'الإجمالي: '
                            '${total.toStringAsFixed(2)} ج',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: checkout,
                          icon: const Icon(
                            Icons.receipt_long,
                          ),
                          label:
                              const Text('بيع'),
                        ),
                      ],
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
  State<ProductsPage> createState() =>
      _ProductsPageState();
}

class _ProductsPageState
    extends State<ProductsPage> {
  String search = '';

  List<Product> get filtered {
    if (search.trim().isEmpty) {
      return widget.products;
    }

    return widget.products.where((p) {
      return p.name
              .toLowerCase()
              .contains(search.toLowerCase()) ||
          p.category
              .toLowerCase()
              .contains(search.toLowerCase());
    }).toList();
  }

  void showProductDialog({
    Product? product,
  }) {
    final nameController =
        TextEditingController(
      text: product?.name ?? '',
    );

    final categoryController =
        TextEditingController(
      text: product?.category ?? 'عام',
    );

    final buyController =
        TextEditingController(
      text: product?.buyPrice.toString() ?? '',
    );

    final sellController =
        TextEditingController(
      text: product?.sellPrice.toString() ?? '',
    );

    final quantityController =
        TextEditingController(
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
                  decoration:
                      const InputDecoration(
                    labelText: 'اسم المنتج',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller:
                      categoryController,
                  decoration:
                      const InputDecoration(
                    labelText: 'التصنيف',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: buyController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'سعر الشراء',
                    suffixText: 'ج',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sellController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'سعر البيع',
                    suffixText: 'ج',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller:
                      quantityController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'الكمية',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    nameController.text.trim();

                final category =
                    categoryController.text
                            .trim()
                            .isEmpty
                        ? 'عام'
                        : categoryController
                            .text
                            .trim();

                final buy =
                    double.tryParse(
                          buyController.text,
                        ) ??
                        0;

                final sell =
                    double.tryParse(
                          sellController.text,
                        ) ??
                        0;

                final quantity =
                    int.tryParse(
                          quantityController
                              .text,
                        ) ??
                        0;

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
                      category: category,
                      buyPrice: buy,
                      sellPrice: sell,
                      quantity: quantity,
                    ),
                  );
                } else {
                  product.name = name;
                  product.category =
                      category;
                  product.buyPrice = buy;
                  product.sellPrice = sell;
                  product.quantity =
                      quantity;

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
          title:
              const Text('حذف المنتج'),
          content: Text(
            'هل تريد حذف "${product.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
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
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            showProductDialog(),
        icon: const Icon(Icons.add),
        label:
            const Text('إضافة منتج'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'بحث في المنتجات...',
                prefixIcon:
                    Icon(Icons.search),
                border:
                    OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    itemCount:
                        filtered.length,
                    itemBuilder:
                        (context, index) {
                      final product =
                          filtered[index];

                      return Card(
                        child: ListTile(
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons.inventory_2,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${product.category}\n'
                            'شراء: ${product.buyPrice.toStringAsFixed(2)} ج • '
                            'بيع: ${product.sellPrice.toStringAsFixed(2)} ج\n'
                            'المخزون: ${product.quantity}',
                          ),
                          isThreeLine: true,
                          trailing:
                              PopupMenuButton<
                                  String>(
                            onSelected:
                                (value) {
                              if (value ==
                                  'edit') {
                                showProductDialog(
                                  product:
                                      product,
                                );
                              }

                              if (value ==
                                  'delete') {
                                confirmDelete(
                                  product,
                                );
                              }
                            },
                            itemBuilder:
                                (context) =>
                                    const [
                              PopupMenuItem(
                                value: 'edit',
                                child:
                                    Text(
                                  'تعديل',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child:
                                    Text(
                                  'حذف',
                                ),
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

    final discounts = sales.fold(
      0.0,
      (sum, sale) => sum + sale.discount,
    );

    final items = sales.fold(
      0,
      (sum, sale) => sum + sale.items,
    );

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              StatCard(
                title: 'المبيعات',
                value:
                    '${total.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'الفواتير',
                value: '${sales.length}',
                icon: Icons.receipt,
              ),
              StatCard(
                title: 'القطع المباعة',
                value: '$items',
                icon: Icons.shopping_cart,
              ),
              StatCard(
                title: 'الخصومات',
                value:
                    '${discounts.toStringAsFixed(2)} ج',
                icon: Icons.discount,
              ),
            ],
          ),
        ),

        const Divider(),

        Expanded(
          child: sales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مبيعات حتى الآن',
                    style:
                        TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder:
                      (context, index) {
                    final sale =
                        sales[sales.length -
                            1 -
                            index];

                    final shortId =
                        sale.id.length > 6
                            ? sale.id.substring(
                                sale.id.length -
                                    6,
                              )
                            : sale.id;

                    return Card(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long,
                          ),
                        ),
                        title: Text(
                          'فاتورة #$shortId',
                        ),
                        subtitle: Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year}'
                          ' • ${sale.items} قطعة\n'
                          'خصم: ${sale.discount.toStringAsFixed(2)} ج',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${sale.total.toStringAsFixed(2)} ج',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
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

  Future<void> openWhatsApp(
      BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/201030415839',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );
    } else {
      showMessage(
        context,
        'تعذر فتح واتساب',
      );
    }
  }

  Future<void> makeCall(
      BuildContext context) async {
    final uri = Uri.parse(
      'tel:01012610087',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage(
        context,
        'تعذر فتح الاتصال',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            secondary: Icon(
              darkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title:
                const Text('الوضع الليلي'),
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
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 55,
                ),
                const SizedBox(height: 10),
                const Text(
                  'للدعم والاستفسارات والشكاوى',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      FilledButton.icon(
                    onPressed: () =>
                        openWhatsApp(
                      context,
                    ),
                    icon:
                        const Icon(Icons.chat),
                    label: const Text(
                      'واتساب الشكاوى',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        makeCall(context),
                    icon:
                        const Icon(Icons.phone),
                    label: const Text(
                      'اتصال مباشر',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'واتساب: 01030415839\n'
                  'المكالمات: 01012610087',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        const Card(
          child: ListTile(
            leading:
                Icon(Icons.info_outline),
            title:
                Text('CASHIER PRO'),
            subtitle:
                Text('الإصدار V4.0'),
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
  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(message),
      behavior:
          SnackBarBehavior.floating,
    ),
  );
}