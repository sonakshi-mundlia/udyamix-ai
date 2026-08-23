import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/dashboard_background_model.dart';
import '../models/dashboard_model.dart';
import '../models/inventory_model.dart';
import '../providers/business_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';

import '../widgets/quick_actions_widget.dart';
import '../widgets/suggested_inventory_widget.dart';
import '../widgets/daily_chart.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/monthly_chart.dart';
import '../widgets/chatbot_wrapper.dart';

import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'expenses_screen.dart';
import 'ai_insights_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ChatbotWrapperState> _chatKey = GlobalKey();

  void openChat() => _chatKey.currentState?.openChat();

  DashboardBackgroundModel? background;
  bool aiError = false;
  int selectedTab = 0;
  int selectedBottomIndex = 0;

  DateTime focusedDate = DateTime.now();
  DateTime selectedDate = DateTime.now();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({DateTime? date}) async {
    final userProvider = context.read<UserProvider>();
    await userProvider.loadFromLocal();
    if (!userProvider.isLoggedIn || userProvider.user == null) return;

    final email = userProvider.user!.email ?? "";
    final mobile = userProvider.user!.mobile;

    final businessProvider = context.read<BusinessProvider>();
    await businessProvider.loadBusinesses(email: email, mobile: mobile);

    final dashboardProvider =
    Provider.of<DashboardProvider>(context, listen: false);

    final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    try {
      final bg = await ApiService.getDashboardBackground(lang);

      setState(() {
        background = bg;
        aiError = bg.aiError;
      });

      await dashboardProvider.loadDashboard(date: date ?? selectedDate);
    } catch (e) {
      setState(() => aiError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    String t(String key) => langProvider.translate(key);

    final businessName =
        context.watch<BusinessProvider>().businessName ?? t("dashboard.business");

    final dashboardProvider = context.watch<DashboardProvider>();
    final dashboardData = dashboardProvider.dashboardData;
    final loading = dashboardProvider.loading;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final suggestions = background?.data ?? [];

    bool hasAnyData() => dashboardProvider.hasAnyData;
    bool hasSales() => dashboardProvider.hasSales;
    bool hasExpenses() => dashboardProvider.hasExpenses;

    final hasInventory = context.watch<InventoryProvider>().items.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: ChatbotWrapper(
        key: _chatKey,
        showFloatingButton: true,
        child: SafeArea(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BUSINESS NAME
                  Text(
                    businessName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // QUICK ACTIONS
                  Text(
                    t("dashboard.quick_actions"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const QuickActionsWidget(),
                  const SizedBox(height: 20),

                  // CALENDAR
                  if (dashboardProvider.hasHistoricalData) _dateCalendar(t),

                  const SizedBox(height: 20),

                  // TABS
                  if (hasAnyData()) _buildTabs(t),
                  const SizedBox(height: 20),

                  // DASHBOARD OR EMPTY
                  if (hasAnyData())
                    _buildSelectedDashboard(dashboardData!, t)
                  else
                    _emptyState(t),
                  const SizedBox(height: 20),

                  // AI SUGGESTIONS
                  const SizedBox(height: 20),

                  // SALES / EXPENSE BUTTONS
                  _dataCards(hasSales(), hasExpenses(), t),
                  const SizedBox(height: 20),

                  // INVENTORY BUTTON

                  if (!hasInventory)
                    Row(
                      children: [
                        Expanded(
                          child: _inventoryButton(t),
                        ),
                        const SizedBox(width: 10),
                      ],
                    )
                  /// ======================================================
                  /// 4. UPDATE INVENTORY + BUTTON UI
                  /// ======================================================

                  else
                    Column(
                      children: [

                        /// INVENTORY SUGGESTIONS
                        SuggestedInventoryWidget(
                          suggestedItems: suggestions,

                          onItemTap: (item) {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => InventoryScreen(
                                  prefillItem: InventoryItem(
                                    productName: item.productName ?? "",
                                    brand: item.brand,
                                    quantity: 0.0,
                                    unit: "kg",
                                    stockQuantity: 0,
                                    pricePerUnit: 0.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        GestureDetector(

                          onTap: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
                              ),
                            );
                          },

                          child: Container(

                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),

                            decoration: BoxDecoration(

                              color: Colors.white,

                              borderRadius: BorderRadius.circular(16),

                              boxShadow: [

                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [

                                Container(
                                  padding: const EdgeInsets.all(6),

                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),

                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                 Text(t("dashboard.add_inventory"),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavIcon(Icons.home, t("dashboard.home"), 0),
            _bottomNavIcon(Icons.lightbulb_outline, t("dashboard.ai_insights"), 1),
            _bottomNavIcon(Icons.person, t("dashboard.profile"), 2),
          ],
        ),
      ),
    );
  }

  // Bottom nav icon
  Widget _bottomNavIcon(IconData icon, String label, int index) {
    final isSelected = selectedBottomIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedBottomIndex = index);

        if (index == 0) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AiInsightsScreen()));
        } else if (index == 2) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Calendar
  Widget _dateCalendar(String Function(String) t) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 HEADER (like your image)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t("dashboard.calendar_title"),
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    t("dashboard.calendar_subtitle"),
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 14,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: focusedDate,

              selectedDayPredicate: (day) =>
                  isSameDay(selectedDate, day),

              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(selectedDate, selectedDay)) {
                  setState(() {
                    selectedDate = selectedDay;
                    focusedDate = focusedDay;
                  });
                  _loadData(date: selectedDay);
                }
              },

              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left),
                rightChevronIcon: const Icon(Icons.chevron_right),
              ),

              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  fontSize: isSmall ? 12 : 14,
                ),
                weekendTextStyle: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: isSmall ? 12 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state
  Widget _emptyState(String Function(String) t) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          t("dashboard.no_data_title"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          t("dashboard.no_data_subtitle"),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // Tabs
  Widget _buildTabs(String Function(String) t) {
    return Row(
      children: [
        _tabItem(t("dashboard.daily"), 0),
        _tabItem(t("dashboard.weekly"), 1),
        _tabItem(t("dashboard.monthly"), 2),
        _tabItem(t("dashboard.total"), 3),
      ],
    );
  }

  Widget _tabItem(String title, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Dashboard switch
  Widget _buildSelectedDashboard(FullDashboardModel dashboardData, String Function(String) t) {
    switch (selectedTab) {
      case 0:
        return DailyDashboard(
          dashboard: dashboardData.daily,
          selectedDate: selectedDate,
        );
      case 1:
        return WeeklyDashboard(
          dashboards: [dashboardData.weekly],
          weekStart: selectedDate,
          weekEnd: selectedDate,
        );
      case 2:
        return MonthlyDashboard(
          dashboards: [dashboardData.monthly],
          month: selectedDate.month,
          year: selectedDate.year,
        );

      case 3:
        return MonthlyDashboard(
          dashboards: [dashboardData.total],
          month: 0,
          year: 0,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _dataCards(bool hasSales, bool hasExpenses, String Function(String) t) {
    return Column(
      children: [
        if (hasSales)
          _navCard(t("dashboard.see_sales"), Colors.green.shade200, Icons.trending_up, const SalesScreen()),
        if (hasExpenses)
          _navCard(t("dashboard.see_expenses"), Colors.orange.shade200, Icons.money_off, const ExpensesScreen()),
      ],
    );
  }

  Widget _navCard(
      String title,
      Color color,
      IconData icon,
      Widget screen, {
        VoidCallback? onReturn,
      }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

        if (result == true) {
          await _loadData(date: selectedDate);
        }

        onReturn?.call();
      },
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _inventoryButton(String Function(String) t) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
        ),
        child: Center(
          child: Text(t("dashboard.see_inventory"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
