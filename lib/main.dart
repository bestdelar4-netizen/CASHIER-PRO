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

class CashierPro extends StatefulWidget {
  const CashierPro({super.key});

  @override
  State<CashierPro> createState() => _CashierProState();
}

class _CashierProState extends State<CashierPro> {
  bool darkMode = false;

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
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        darkMode: darkMode,
        onThemeChanged: (value) {
          setState(() {
            darkMode = value;
          });
        },
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

  Product({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
  });

  double get profit => sellPrice - buyPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      buyPrice: (json['buyPrice'] ?? json['price'] ?? 0 as num).toDouble(),
      sellPrice: (json['sellPrice'] ?? json['price'] ?? 0 as num).toDouble(),
      quantity: (json['quantity'] ?? 0 as num).toInt(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'paid': paid,
      'change': change,
      'profit': profit,
      'items': items,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'].toString()),
      total: (json['total'] as num).toDouble(),
      paid: (json['paid'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      profit: (json['profit'] ?? 0 as num).toDouble(),
      items: (json['items'] ?? 0 as num).toInt(),
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
      final productsData = prefs.getString('products_v4');
      final salesData = prefs.getString('sales_v4');

      if (productsData != null) {
        final decoded = jsonDecode(productsData);

        if (decoded is List) {
          products = decoded
              .map(
                (item) => Product.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      if (salesData != null) {
        final decoded = jsonDecode(salesData);

        if (decoded is List) {
          sales = decoded
              .map(
                (item) => Sale.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }
    } catch (_) {
      products = [];
      sales = [];
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products_v4',
      jsonEncode(
        products.map((product) => product.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'sales_v4',
      jsonEncode(
        sales.map((sale) => sale.toJson()).toList(),
      ),
    );
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
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  double get todayProfit {
    final now = DateTime.now();

    return sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold(0.0, (sum, sale) => sum + sale.profit);
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

  double get totalSales {
    return sales.fold(
      0.0,
      (sum, sale) => sum + sale.total,
    );
  }

  double get totalProfit {
    return sales.fold(
      0.0,
      (sum, sale) => sum + sale.profit,
    );
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
      products.removeWhere(
        (item) => item.id == product.id,
      );
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
        todaySales: todaySales,
        todayProfit: todayProfit,
        todayInvoices: todayInvoices,
        totalSales: totalSales,
        totalProfit: totalProfit,
      ),
      CashierPage(
        products: products,
        onSaleComplete: completeSale,
        onStockChanged: saveData,
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
    final lowStock = products
        .where((product) => product.quantity <= 5)
        .toList();

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

          const SizedBox(height: 6),

          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'نظام إدارة المبيعات والمخزون',
              style: TextStyle(fontSize: 15),
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width >= 800
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatCard(
                title: 'مبيعات اليوم',
                value:
                    '${todaySales.toStringAsFixed(2)} ج',
                icon: Icons.payments,
              ),
              StatCard(
                title: 'أرباح اليوم',
                value:
                    '${todayProfit.toStringAsFixed(2)} ج',
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
                icon: Icons.inventory_2,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            child: ListTile(
              leading: Icon(
                lowStock.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              title: const Text(
                'حالة المخزون',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lowStock.isEmpty
                    ? 'المخزون جيد حاليًا'
                    : '${lowStock.length} منتج منخفض المخزون',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.analytics_outlined,
              ),
              title: const Text(
                'إجمالي المبيعات',
              ),
              trailing: Text(
                '${totalSales.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
              ),
              title: const Text(
                'إجمالي الأرباح',
              ),
              trailing: Text(
                '${totalProfit.toStringAsFixed(2)} ج',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.end,
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
  final VoidCallback onStockChanged;

  const CashierPage({
    super.key,
    required this.products,
    required this.onSaleComplete,
    required this.onStockChanged,
  });

  @override
  State<CashierPage> createState() =>
      _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<CartItem> cart = [];

  String search = '';

  double get total {
    return cart.fold(
      0.0,
      (sum, item) => sum + item.total,
    );
  }

  double get profit {
    return cart.fold(
      0.0,
      (sum, item) => sum + item.profit,
    );
  }

  List<Product> get filteredProducts {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.products;
    }

    return widget.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query),
        )
        .toList();
  }

  void addToCart(Product product) {
    if (product.quantity <= 0) {
      showMessage(
        context,
        'المنتج غير متوفر في المخزون',
      );
      return;
    }

    final index = cart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index >= 0) {
      if (cart[index].quantity >= product.quantity) {
        showMessage(
          context,
          'لا توجد كمية إضافية',
        );
        return;
      }

      setState(() {
        cart[index].quantity++;
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

  void increaseItem(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      showMessage(
        context,
        'الكمية المطلوبة أكبر من المخزون',
      );
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  void decreaseItem(CartItem item) {
    if (item.quantity <= 1) {
      setState(() {
        cart.remove(item);
      });
      return;
    }

    setState(() {
      item.quantity--;
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
          content: TextField(
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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

    final saleTotal = total;
    final saleProfit = profit;
    final saleItems = cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    for (final item in cart) {
      item.product.quantity -= item.quantity;

      if (item.product.quantity < 0) {
        item.product.quantity = 0;
      }
    }

    final sale = Sale(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      date: DateTime.now(),
      total: saleTotal,
      paid: paid,
      change: paid - saleTotal,
      profit: saleProfit,
      items: saleItems,
    );

    widget.onSaleComplete(sale);
    widget.onStockChanged();

    setState(() {
      cart.clear();
    });

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تم البيع بنجاح ✅',
          ),
          content: Text(
            'الإجمالي: '
            '${sale.total.toStringAsFixed(2)} ج\n'
            'المدفوع: '
            '${sale.paid.toStringAsFixed(2)} ج\n'
            'الباقي: '
            '${sale.change.toStringAsFixed(2)} ج\n'
            'الربح: '
            '${sale.profit.toStringAsFixed(2)} ج',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
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
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              suffixIcon: search.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          search = '';
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                      ),
                    )
                  : null,
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
                    style: TextStyle(
                      fontSize: 20,
                    ),
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
                                    .width >=
                                800
                            ? 4
                            : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount:
                      filteredProducts.length,
                  itemBuilder:
                      (context, index) {
                    final product =
                        filteredProducts[index];

                    return Card(
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap: () {
                          addToCart(product);
                        },
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
                                Icons
                                    .shopping_bag_outlined,
                                size: 34,
                              ),
                              const SizedBox(
                                height: 7,
                              ),
                              Text(
                                product.name,
                                maxLines: 2,
                                textAlign:
                                    TextAlign.center,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
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
                        child: Text(
                          'السلة فارغة',
                        ),
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
                              Icons
                                  .shopping_cart,
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
                                      decreaseItem(
                                    item,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons
                                        .remove_circle_outline,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      increaseItem(
                                    item,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons
                                        .add_circle_outline,
                                  ),
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  '${item.total.toStringAsFixed(2)} ج',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
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
                    const EdgeInsets.fromLTRB(
                  12,
                  5,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الإجمالي: '
                        '${total.toStringAsFixed(2)} ج',
                        style:
                            const TextStyle(
                          fontSize: 19,
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

  List<Product> get filteredProducts {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.products;
    }

    return widget.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(
                    query,
                  ),
        )
        .toList();
  }

  void showProductDialog({
    Product? product,
  }) {
    final nameController =
        TextEditingController(
      text: product?.name ?? '',
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

                const SizedBox(height: 12),

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

                const SizedBox(height: 12),

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

                const SizedBox(height: 12),

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
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    nameController.text.trim();

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
                          quantityController.text,
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
                      buyPrice: buy,
                      sellPrice: sell,
                      quantity: quantity,
                    ),
                  );
                } else {
                  product.name = name;
                  product.buyPrice = buy;
                  product.sellPrice = sell;
                  product.quantity =
                      quantity;

                  widget.onUpdate(product);
                }

                Navigator.pop(context);
              },
              child:
                  const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void confirmDelete(
    Product product,
  ) {
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
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                widget.onDelete(product);
                Navigator.pop(context);
              },
              child:
                  const Text('حذف'),
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
        onPressed: () {
          showProductDialog();
        },
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
                  InputDecoration(
                hintText:
                    'ابحث عن منتج...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                border:
                    const OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child:
                filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد منتجات',
                          style:
                              TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                        ),
                        itemCount:
                            filteredProducts
                                .length,
                        itemBuilder:
                            (context, index) {
                          final product =
                              filteredProducts[
                                  index];

                          return Card(
                            child:
                                ListTile(
                              leading:
                                  const CircleAvatar(
                                child:
                                    Icon(
                                  Icons
                                      .inventory_2,
                                ),
                              ),
                              title: Text(
                                product.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              subtitle:
                                  Text(
                                'شراء: ${product.buyPrice.toStringAsFixed(2)} ج\n'
                                'بيع: ${product.sellPrice.toStringAsFixed(2)} ج\n'
                                'المخزون: ${product.quantity} • الربح: ${product.profit.toStringAsFixed(2)} ج',
                              ),
                              isThreeLine:
                                  true,
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
                                    value:
                                        'edit',
                                    child:
                                        Text(
                                      'تعديل',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value:
                                        'delete',
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

class ReportsPage
    extends StatefulWidget {
  final List<Sale> sales;

  const ReportsPage({
    super.key,
    required this.sales,
  });

  @override
  State<ReportsPage> createState() =>
      _ReportsPageState();
}

class _ReportsPageState
    extends State<ReportsPage> {
  bool todayOnly = false;

  List<Sale> get filteredSales {
    if (!todayOnly) {
      return widget.sales;
    }

    final now = DateTime.now();

    return widget.sales.where(
      (sale) =>
          sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day,
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = filteredSales.fold(
      0.0,
      (sum, sale) => sum + sale.total,
    );

    final profit = filteredSales.fold(
      0.0,
      (sum, sale) => sum + sale.profit,
    );

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.payments,
                    ),
                    title:
                        const Text(
                      'المبيعات',
                    ),
                    subtitle: Text(
                      '${total.toStringAsFixed(2)} ج',
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.trending_up,
                    ),
                    title:
                        const Text(
                      'الأرباح',
                    ),
                    subtitle: Text(
                      '${profit.toStringAsFixed(2)} ج',
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label:
                    Text('كل المبيعات'),
                icon: Icon(
                  Icons.list,
                ),
              ),
              ButtonSegment<bool>(
                value: true,
                label:
                    Text('اليوم'),
                icon: Icon(
                  Icons.today,
                ),
              ),
            ],
            selected: {todayOnly},
            onSelectionChanged:
                (value) {
              setState(() {
                todayOnly = value.first;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: filteredSales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مبيعات',
                    style:
                        TextStyle(
                      fontSize: 20,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount:
                      filteredSales.length,
                  itemBuilder:
                      (context, index) {
                    final sale =
                        filteredSales[
                            filteredSales
                                    .length -
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
                            Icons.receipt,
                          ),
                        ),
                        title: Text(
                          'فاتورة #$shortId',
                        ),
                        subtitle:
                            Text(
                          '${sale.date.day}/${sale.date.month}/${sale.date.year} • '
                          '${sale.items} قطعة • '
                          'ربح ${sale.profit.toStringAsFixed(2)} ج',
                        ),
                        trailing:
                            Text(
                          '${sale.total.toStringAsFixed(2)} ج',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
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

class SettingsPage
    extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool>
      onThemeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  Future<void> openWhatsApp(
    BuildContext context,
  ) async {
    final uri = Uri.parse(
      'https://wa.me/201030415839',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication,
      );
    } else {
      showMessage(
        context,
        'تعذر فتح واتساب',
      );
    }
  }

  Future<void> makeCall(
    BuildContext context,
  ) async {
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
          child:
              SwitchListTile(
            secondary: Icon(
              darkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title:
                const Text(
              'الوضع الليلي',
            ),
            subtitle:
                const Text(
              'تغيير مظهر البرنامج',
            ),
            value: darkMode,
            onChanged:
                onThemeChanged,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'الدعم والشكاوى',
          style:
              TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 55,
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'للدعم والاستفسارات والشكاوى',
                  textAlign:
                      TextAlign.center,
                  style: