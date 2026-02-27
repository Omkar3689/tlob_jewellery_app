import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const TlobJewelleryApp(),
    ),
  );
}

class TiaraTheme {
  static const Color softPeach = Color(0xFFFDF0ED);
  static const Color deepRose = Color(0xFFD84339);
  static const Color woodBrown = Color(0xFF704214);
}

// --- STATE MANAGEMENT ---
class CartProvider with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _items = {};
  List<Map<String, dynamic>> get items => _items.values.toList();

  void addToCart(Map<String, dynamic> product) {
    String id = product['name'];
    if (_items.containsKey(id)) {
      _items[id]!['quantity'] += 1;
    } else {
      _items[id] = {...product, 'quantity': 1};
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    if (!_items.containsKey(id)) return;
    _items[id]!['quantity'] += delta;
    if (_items[id]!['quantity'] <= 0) {
      _items.remove(id);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get totalPrice => _items.values.fold(0, (sum, item) =>
  sum + (double.parse(item['price'].toString()) * item['quantity']));

  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + (item['quantity'] as int));
}

class TlobJewelleryApp extends StatelessWidget {
  const TlobJewelleryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.playfairDisplayTextTheme(),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return const MainDashboard();
          return const LandingScreen();
        },
      ),
    );
  }
}

// --- LANDING & AUTH SCREENS ---
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.network('https://images.pexels.com/photos/11203822/pexels-photo-11203822.jpeg', fit: BoxFit.cover)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TLOB", style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 50, letterSpacing: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Crafting Timeless Elegance\nFor Every Occasion.", style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, height: 1.2)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen())),
                    child: const Text("SHOP NOW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Find this inside _AuthScreenState
  Future<void> _authenticate() async {
    final email = _emailController.text.trim(); // Add .trim() here
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.network('https://images.pexels.com/photos/7743081/pexels-photo-7743081.jpeg', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: TiaraTheme.softPeach, size: 50),
                const SizedBox(height: 20),
                Text(isLogin ? "Welcome Back" : "Join TLOB", style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                _buildTextField("Email", _emailController),
                const SizedBox(height: 20),
                _buildTextField("Password", _passwordController, obscure: true),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: TiaraTheme.deepRose), onPressed: isLoading ? null : _authenticate, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(color: Colors.white))),
                ),
                TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Create an account" : "Have an account? Login", style: const TextStyle(color: Colors.white70))),
              ],
            ),
          ),
          Positioned(top: 50, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
    );
  }
}

// --- MAIN DASHBOARD ---
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  String searchQuery = "";
  String selectedCategory = "Home";
  String? selectedSubCategory;

  final List<String> categories = ["Home", "Necklace", "Haram", "Chokers", "Earrings", "Bangles", "New Arrivals"];
  final Map<String, List<String>> subCategories = {
    "Necklace": ["Matt Necklace", "Antique Necklace", "AD & CZ Necklace"],
  };

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final List<Widget> pages = [_buildHomeScreen(cart), _buildCartScreen(cart), _buildProfileScreen()];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: TiaraTheme.deepRose,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Badge(
                label: Text(cart.totalQuantity.toString()),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              label: "Cart"
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Opacity(opacity: 0.9, child: Image.network('https://images.pexels.com/photos/691046/pexels-photo-691046.jpeg', fit: BoxFit.cover))),
            pages[_currentIndex],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen(CartProvider cart) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TLOB", style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
                IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search jewellery...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, i) {
                String cat = categories[i];
                bool hasSub = subCategories.containsKey(cat);
                if (hasSub) {
                  return PopupMenuButton<String>(
                    onSelected: (sub) => setState(() { selectedCategory = cat; selectedSubCategory = sub; }),
                    itemBuilder: (context) => subCategories[cat]!.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(children: [Text(cat, style: TextStyle(color: selectedCategory == cat ? TiaraTheme.deepRose : Colors.black, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down)]),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => setState(() { selectedCategory = cat; selectedSubCategory = null; }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Text(cat, style: TextStyle(color: selectedCategory == cat ? TiaraTheme.deepRose : Colors.black, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ),
        _buildProductGrid(isSearch: searchQuery.isNotEmpty),
      ],
    );
  }

  Widget _buildProductGrid({required bool isSearch}) {
    Query query = FirebaseFirestore.instance.collection('products');
    if (!isSearch) {
      if (selectedSubCategory != null) query = query.where('subCategory', isEqualTo: selectedSubCategory);
      else if (selectedCategory != "Home") query = query.where('category', isEqualTo: selectedCategory);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        var docs = snapshot.data!.docs;
        if (isSearch) docs = docs.where((d) => d['name'].toString().toLowerCase().contains(searchQuery)).toList();
        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.7),
            delegate: SliverChildBuilderDelegate((context, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(data: data))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity))),
                    const SizedBox(height: 10),
                    Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("₹${data['price']}", style: const TextStyle(color: TiaraTheme.deepRose, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }, childCount: docs.length),
          ),
        );
      },
    );
  }

  Widget _buildCartScreen(CartProvider cart) {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("Shopping Bag", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold))
        ),
        Expanded(
          child: cart.items.isEmpty
              ? const Center(child: Text("Your bag is empty"))
              : ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (context, i) {
              final item = cart.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['imageUrl'],
                        width: 100,
                        height: 140, // Tall image height
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text("₹${item['price']}", style: const TextStyle(color: TiaraTheme.deepRose, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => cart.updateQuantity(item['name'], -1),
                              ),
                              Text("${item['quantity']}", style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => cart.updateQuantity(item['name'], 1),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => cart.removeItem(item['name']),
                              ),
                            ],
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
        if (cart.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: TiaraTheme.deepRose,
                  foregroundColor: Colors.white, // Visible white text
                  minimumSize: const Size(double.infinity, 55)
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen())),
              child: Text("PROCEED TO CHECKOUT (₹${cart.totalPrice})"),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.account_circle, size: 80, color: Colors.brown),
        Text(user?.email ?? "Guest", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Logout", style: TextStyle(color: Colors.indigoAccent))),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userEmail', isEqualTo: user?.email)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var orderDoc = snapshot.data!.docs[index];
                  var orderData = orderDoc.data() as Map<String, dynamic>;

                  // Change 'orderStatus' to 'status' to match your Firestore data
                  String orderStatus = orderData.containsKey('status') ? orderData['status'] : 'Processing';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrderDetailScreen(orderData: orderData)),
                      ),
                      title: Text("Order ₹${orderData['totalAmount']}"),
                      subtitle: Text("Status: $orderStatus • Tap to view items"),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeleteOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cancel Order?", style: GoogleFonts.playfairDisplay()),
        content: const Text("Are you sure you want to cancel this order? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("YES, CANCEL", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}

// --- CHECKOUT SCREEN ---
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String _selectedPaymentMethod = "UPI";
  bool isLoading = false;

  // 1. PAYMENT GATEWAY LOGIC
  void _handlePayment(CartProvider cart) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaymentMethod == "Stripe") {
      _showStripePaymentSheet(cart);
    } else if (_selectedPaymentMethod == "UPI") {
      _showDummyQRCode(cart);
    } else {
      _processFinalOrder(cart);
    }
  }

  // 2. STRIPE CREDIT CARD SHEET
  void _showStripePaymentSheet(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Card Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF32325D))),
            const SizedBox(height: 15),
            _buildStripeField("Card Number", TextEditingController()),
            Row(children: [
              Expanded(child: _buildStripeField("MM/YY", TextEditingController())),
              const SizedBox(width: 15),
              Expanded(child: _buildStripeField("CVC", TextEditingController())),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6772E5), minimumSize: const Size(double.infinity, 55)),
              onPressed: () { Navigator.pop(context); _processFinalOrder(cart); },
              child: Text("Pay ₹${cart.totalPrice}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // 3. UPI QR DIALOG
  void _showDummyQRCode(CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Pay"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 200),
            const SizedBox(height: 10),
            Text("Amount: ₹${cart.totalPrice}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _processFinalOrder(cart); }, child: const Text("Payment Done")),
        ],
      ),
    );
  }

  // 4. FIREBASE ORDER PROCESS
  void _processFinalOrder(CartProvider cart) async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('orders').add({
        'userEmail': user?.email,
        'customerName': "${_fName.text} ${_lName.text}",
        'shippingAddress': _address.text,
        'phone': _phone.text,
        'items': cart.items,
        'totalAmount': cart.totalPrice,
        'status': 'Processing',
        'timestamp': FieldValue.serverTimestamp(),
      });
      cart.clearCart();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const OrderSuccessScreen()), (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("CHECKOUT"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(25),
          children: [
            _sectionHeader("Shipping Details"),
            Row(children: [
              Expanded(child: _buildStripeField("First Name", _fName)),
              const SizedBox(width: 15),
              Expanded(child: _buildStripeField("Last Name", _lName)),
            ]),
            _buildStripeField("Address", _address),
            _buildStripeField("Phone", _phone, isNumber: true),
            const SizedBox(height: 20),
            _sectionHeader("Payment Method"),
            _buildPaymentOption("UPI", "GPay/PhonePe", Icons.account_balance_wallet),
            _buildPaymentOption("Stripe", "Card Payment", Icons.credit_card),
            _buildPaymentOption("COD", "Cash on Delivery", Icons.payments),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6772E5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60)),
              onPressed: () => _handlePayment(cart),
              child: const Text("PROCEED", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER UI WIDGETS
  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  Widget _buildStripeField(String l, TextEditingController c, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
  Widget _buildPaymentOption(String v, String s, IconData i) {
    return RadioListTile(
      value: v, groupValue: _selectedPaymentMethod, title: Text(v), subtitle: Text(s), secondary: Icon(i),
      onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
    );
  }
}

// --- PRODUCT DETAILS SCREEN ---
class ProductDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductDetails({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Expanded(child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity)),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'], style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("₹${data['price']}", style: const TextStyle(fontSize: 24, color: TiaraTheme.deepRose, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(data['description'] ?? "Crafted with pure elegance and precision."),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: TiaraTheme.deepRose), onPressed: () { cart.addToCart(data); Navigator.pop(context); }, child: const Text("ADD TO BAG", style: TextStyle(color: Colors.white)))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- ORDER SUCCESS SCREEN ---
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: TiaraTheme.softPeach, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, size: 60, color: TiaraTheme.deepRose),
              ),
              const SizedBox(height: 40),
              Text("THANK YOU", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8)),
              const SizedBox(height: 10),
              const Text("Your order has been placed successfully.", textAlign: TextAlign.center),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: TiaraTheme.deepRose, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text("CONTINUE SHOPPING", style: TextStyle(color: Colors.white, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    List items = orderData['items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // SHIPPING ADDRESS SECTION
          Container(
            padding: const EdgeInsets.all(20),
            color: TiaraTheme.softPeach.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SHIPPING ADDRESS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Text(orderData['customerName'] ?? "No Name", style: const TextStyle(fontSize: 16)),
                Text(orderData['shippingAddress'] ?? "No Address"),
                Text("Phone: ${orderData['phone'] ?? "No Phone"}"),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("ITEMS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          // ITEMS LIST
          ...items.map((item) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['imageUrl'], width: 70, height: 90, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Qty: ${item['quantity']} | ₹${item['price']}"),
                  ],
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}