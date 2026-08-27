import 'package:flutter/material.dart';

void main() {
  runApp(const CashierProApp());
}

class CashierProApp extends StatelessWidget {
  const CashierProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cashier Pro V2',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101216),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: CashierHome(),
      ),
    );
  }
}

class Product {
  String name;
  double price;
  int stock;

  Product({
    required this.name,
    required this.price,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}

class SaleItem {
  final String name;
  final double price;
  final int quantity;

  SaleItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class Sale {
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final double paid;

  Sale({
    required this.date,
    required this.items,
    required this.total,
    required this.paid,
  });

  double get change => paid - total;
}

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  int currentIndex = 0;

  final List<Product> products = [
    Product(name: 'مياه معدنية', price: 10, stock: 50),
    Product(name: 'عصير', price: 20, stock: 30),
    Product(name: 'مشروب غازي', price: 25, stock: 25),
    Product(name: 'شيبسي', price: 15, stock: 40),
  ];

  final List<CartItem> cart = [];
  final List<Sale> sales = [];

  String searchText = '';

  double get cartTotal {
    return cart.fold(0, (sum, item) => sum + item.total);
  }

  int get cartCount {
    return cart.fold(0, (sum, item) => sum + item.quantity);
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

    return sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .length;
  }

  List<Product> get filteredProducts {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  void addToCart(Product product) {
    if (product.stock <= 0) {
      showMessage('المنتج غير متوفر في المخزون');
      return;
    }

    final index = cart.indexWhere(
      (item) => identical(item.product, product),
    );

    setState(() {
      if (index == -1) {
        cart.add(CartItem(product: product));
      } else {
        if (cart[index].quantity < product.stock) {
          cart[index].quantity++;
        } else {
          showMessage('لا توجد كمية إضافية في المخزون');
        }
      }
    });
  }

  void increaseCart(int index) {
    final item = cart[index];

    if (item.quantity >= item.product.stock) {
      showMessage('الكمية المطلوبة أكبر من المخزون');
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  void decreaseCart(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void removeCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void addProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة منتج'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية في المخزون',
                    prefixIcon: Icon(Icons.warehouse_outlined),
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
                final price = double.tryParse(
                  priceController.text.trim(),
                );
                final stock = int.tryParse(
                  stockController.text.trim(),
                );

                if (name.isEmpty ||
                    price == null ||
                    price < 0 ||
                    stock == null ||
                    stock < 0) {
                  showMessage('أدخل بيانات صحيحة');
                  return;
                }

                setState(() {
                  products.add(
                    Product(
                      name: name,
                      price: price,
                      stock: stock,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void editProductDialog(int index) {
    final product = products[index];

    final nameController = TextEditingController(
      text: product.name,
    );

    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    final stockController = TextEditingController(
      text: product.stock.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المنتج'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المخزون',
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
                final price = double.tryParse(
                  priceController.text.trim(),
                );
                final stock = int.tryParse(
                  stockController.text.trim(),
                );

                if (name.isEmpty ||
                    price == null ||
                    price < 0 ||
                    stock == null ||
                    stock < 0) {
                  showMessage('أدخل بيانات صحيحة');
                  return;
                }

                setState(() {
                  product.name = name;
                  product.price = price;
                  product.stock = stock;
                });

                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void deleteProduct(int index) {
    final product = products[index];

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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  cart.removeWhere(
                    (item) => identical(item.product, product),
                  );
                  products.removeAt(index);
                });

                Navigator.pop(context);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  void finishSale() {
    if (cart.isEmpty) {
      showMessage('السلة فارغة');
      return;
    }

    final paidController = TextEditingController(
      text: cartTotal.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إجمالي الفاتورة'),
              const SizedBox(height: 4),
              Text(
                '${cartTotal.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: paidController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  prefixIcon: Icon(Icons.payments_outlined),
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
                final paid = double.tryParse(
                  paidController.text.trim(),
                );

                if (paid == null || paid < cartTotal) {
                  showMessage('المبلغ المدفوع غير كافٍ');
                  return;
                }

                for (final item in cart) {
                  if (item.quantity > item.product.stock) {
                    showMessage(
                      'المخزون غير كافٍ للمنتج ${item.product.name}',
                    );
                    return;
                  }
                }

                final items = cart
                    .map(
                      (item) => SaleItem(
                        name: item.product.name,
                        price: item.product.price,
                        quantity: item.quantity,
                      ),
                    )
                    .toList();

                final total = cartTotal;

                setState(() {
                  for (final item in cart) {
                    item.product.stock -= item.quantity;
                  }

                  sales.add(
                    Sale(
                      date: DateTime.now(),
                      items: items,
                      total: total,
                      paid: paid,
                    ),
                  );

                  cart.clear();
                });

                Navigator.pop(context);

                showMessage(
                  'تم البيع بنجاح - الباقي '
                  '${(paid - total).toStringAsFixed(2)} جنيه',
                );
              },
              child: const Text('تأكيد البيع'),
            ),
          ],
        );
      },
    );
  }

  Widget productCard(Product product) {
    final index = products.indexOf(product);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2,
              size: 40,
            ),
            const SizedBox(height: 7),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.price.toStringAsFixed(2)} جنيه',
            ),
            const SizedBox(height: 3),
            Text(
              'المخزون: ${product.stock}',
              style: TextStyle(
                color: product.stock == 0
                    ? Colors.red
                    : product.stock <= 5
                        ? Colors.orange
                        : null,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: product.stock > 0
                        ? () => addToCart(product)
                        : null,
                    child: const Text('إضافة'),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      editProductDialog(index);
                    } else if (value == 'delete') {
                      deleteProduct(index);
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCashier() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Cashier Pro',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.shopping_cart),
                ),
              ),
              const SizedBox(width: 5),
              FilledButton.icon(
                onPressed: addProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('منتج'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          searchText = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text('لا توجد منتجات'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisExtent: 190,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return productCard(
                            filteredProducts[index],
                          );
                        },
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: buildCart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCart() {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'السلة',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (cart.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        cart.clear();
                      });
                    },
                    child: const Text('مسح'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                        title: Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.product.price.toStringAsFixed(2)} × '
                          '${item.quantity} = '
                          '${item.total.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => decreaseCart(index),
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
                              onPressed: () => increaseCart(index),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الإجمالي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${cartTotal.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: finishSale,
                    icon: const Icon(Icons.check_circle),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('إتمام البيع'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSales() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'المبيعات',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${todaySales.toStringAsFixed(2)} جنيه اليوم',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: statCard(
                  'مبيعات اليوم',
                  '${todaySales.toStringAsFixed(2)}',
                  Icons.payments,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: statCard(
                  'الفواتير',
                  '$todayInvoices',
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: statCard(
                  'كل المبيعات',
                  '${sales.fold<double>(
                    0,
                    (sum, sale) => sum + sale.total,
                  ).toStringAsFixed(2)}',
                  Icons.bar_chart,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: sales.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد فواتير حتى الآن',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale =
                        sales[sales.length - 1 - index];

                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(
                          'فاتورة #${sales.length - index}',
                        ),
                        subtitle: Text(
                          '${formatDate(sale.date)} • '
                          '${sale.total.toStringAsFixed(2)} جنيه',
                        ),
                        children: [
                          ...sale.items.map(
                            (item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.price.toStringAsFixed(2)} × '
                                '${item.quantity}',
                              ),
                              trailing: Text(
                                '${item.total.toStringAsFixed(2)} جنيه',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('المدفوع'),
                                ),
                                Text(
                                  '${sale.paid.toStringAsFixed(2)} جنيه',
                                ),
                                const SizedBox(width: 20),
                                const Text('الباقي'),
                                const SizedBox(width: 5),
                                Text(
                                  '${sale.change.toStringAsFixed(2)} جنيه',
                                ),
                              ],
                            ),
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

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
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

  String formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute';
  }

  Widget buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.store),
            title: const Text('اسم المتجر'),
            subtitle: const Text('Cashier Pro'),
            trailing: const Icon(Icons.edit),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('عدد المنتجات'),
            trailing: Text('${products.length}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('عدد الفواتير'),
            trailing: Text('${sales.length}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('الإصدار'),
            subtitle: const Text('Cashier Pro V2'),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ملاحظة: البيانات الحالية مؤقتة، وسيتم إضافة التخزين الدائم في V3.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (currentIndex) {
      case 1:
        body = buildSales();
        break;
      case 2:
        body = buildSettings();
        break;
      default:
        body = buildCashier();
    }

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'الكاشير',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'المبيعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}