import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../services/weather_service.dart';
import '../search/search_screen.dart';
import '../map/track_bus_screen.dart';
import '../nearby/nearby_buses_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../cards/my_transport_card_screen.dart';
import '../cards/apply_card_screen.dart';
import '../driver/driver_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final AnimationController _busCtrl;
  late final Animation<double> _busProgress;
  late final PageController _carouselController;
  late final Timer _carouselTimer;
  late final Timer _greetingTimer;
  late final Future<WeatherSnapshot?> _weatherFuture;
  late final ValueNotifier<String> _greetingNotifier;
  int _carouselIndex = 0;

  final List<_CarouselItem> _carouselItems = const [
    _CarouselItem(
      title: 'Track Your Bus Live',
      subtitle: 'View live location of your bus in real-time',
      cta: 'Track Now',
      gradient: LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _CarouselItem(
      title: 'Apply for Transport Card',
      subtitle: 'Get your campus travel card in a few steps',
      cta: 'Apply Now',
      gradient: LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _CarouselItem(
      title: 'View Bus Schedule',
      subtitle: 'Check updated departure timings instantly',
      cta: 'View Schedule',
      gradient: LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic),
    );
    _busCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _busProgress = Tween<double>(begin: -0.2, end: 1.1).animate(
      CurvedAnimation(parent: _busCtrl, curve: Curves.linear),
    );
    _carouselController = PageController(viewportFraction: 1);
    _weatherFuture = WeatherService.fetchCampusWeather();
    _greetingNotifier = ValueNotifier<String>(_buildGreeting(DateTime.now()));
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nextGreeting = _buildGreeting(DateTime.now());
      if (_greetingNotifier.value != nextGreeting) {
        _greetingNotifier.value = nextGreeting;
      }
    });
    _headerCtrl.forward();
    _startAutoCarousel();
  }

  String _buildGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning 👋';
    if (hour >= 12 && hour < 15) return 'Good Noon ☀️';
    if (hour >= 15 && hour < 18) return 'Good Afternoon 🌤';
    if (hour >= 18 && hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  void _startAutoCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_carouselController.hasClients) return;
      final nextIndex = (_carouselIndex + 1) % _carouselItems.length;
      _carouselController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _greetingTimer.cancel();
    _greetingNotifier.dispose();
    _busCtrl.dispose();
    _headerCtrl.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: AppConstants.medAnim,
      ),
    );
  }

  void _showComingSoonToast(String featureName) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2600),
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937).withOpacity(0.97)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$featureName is under development. Feature coming soon.',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isDarkMode = ref.watch(themeModeProvider);

    final actionItems = [
      _DashboardItem(
        icon: Icons.search_rounded,
        label: 'Search Bus',
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2A66), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const SearchScreen()),
      ),
      _DashboardItem(
        icon: Icons.gps_fixed_rounded,
        label: 'Track Bus',
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const TrackBusScreen()),
      ),
      _DashboardItem(
        icon: Icons.near_me_rounded,
        label: 'Nearby Buses',
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const NearbyBusesScreen()),
      ),
      _DashboardItem(
        icon: Icons.chat_bubble_rounded,
        label: 'Chatbot',
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const ChatbotScreen()),
      ),
      _DashboardItem(
        icon: Icons.directions_bus_rounded,
        label: 'Transport Card',
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const MyTransportCardScreen()),
      ),
      _DashboardItem(
        icon: Icons.badge_rounded,
        label: 'Apply for Card',
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const ApplyCardScreen()),
      ),
      _DashboardItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Payment',
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showComingSoonToast('Payment'),
      ),
      _DashboardItem(
        icon: Icons.calendar_month_rounded,
        label: 'Schedule',
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigate(const ScheduleScreen()),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0B215A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B215A), Color(0xFF3D79DA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0, -0.18),
                        child: Opacity(
                          opacity: 0.45,
                          child: ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                const Color(0xFF1E40AF).withOpacity(0.40),
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                'assets/images/diu_header.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF1D4ED8).withOpacity(0.20),
                      ),
                    ),
                    // Lower header foreground: darker road layer + transport animation.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 88,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0x003B82F6), Color(0xCC1E3A8A)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 44,
                            child: Opacity(
                              opacity: 0.86,
                              child: SizedBox(
                                height: 2,
                                child: CustomPaint(
                                  painter: _DashedRoadLinePainter(),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _busProgress,
                              builder: (context, child) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final laneWidth = constraints.maxWidth;
                                    final busLeft =
                                        (_busProgress.value * laneWidth) - 18;
                                    return Stack(
                                      children: [
                                        // Edge fades for natural enter/exit.
                                        Positioned(
                                          left: 0,
                                          top: 20,
                                          bottom: 0,
                                          width: 30,
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xAA1D4ED8),
                                                    Color(0x001D4ED8)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 20,
                                          bottom: 0,
                                          width: 30,
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0x001D4ED8),
                                                    Color(0xAA1D4ED8)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: busLeft,
                                          top: 23,
                                          child: const _HeaderBusWidget(),
                                        ),
                                        Positioned(
                                          left: busLeft + 5,
                                          top: 42,
                                          child: Container(
                                            width: 32,
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.24),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TrackDIU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ValueListenableBuilder<String>(
                                      valueListenable: _greetingNotifier,
                                      builder: (context, greeting, _) {
                                        return Text(
                                          greeting,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    _HeaderWeatherLine(weatherFuture: _weatherFuture),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _GlassIconButton(
                                      icon: isDarkMode
                                          ? Icons.wb_sunny_rounded
                                          : Icons.nightlight_round,
                                      onTap: () => ref.read(themeModeProvider.notifier).state =
                                          !isDarkMode,
                                    ),
                                    const SizedBox(width: 10),
                                    _GlassIconButton(
                                      icon: Icons.person_outline_rounded,
                                      onTap: () => _navigate(const ProfileScreen()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _RoleBanner(role: role),
                const SizedBox(height: 20),
                GridView.builder(
                  itemCount: actionItems.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (_, index) {
                    final item = actionItems[index];
                    return _ActionCard(item: item);
                  },
                ),
                const SizedBox(height: 24),
                _PromoCarousel(
                  items: _carouselItems,
                  controller: _carouselController,
                  currentIndex: _carouselIndex,
                  onPageChanged: (index) {
                    setState(() => _carouselIndex = index);
                  },
                  onCardTap: (index) {
                    if (index == 0) {
                      _navigate(const TrackBusScreen());
                      return;
                    }
                    if (index == 1) {
                      _navigate(const ApplyCardScreen());
                      return;
                    }
                    _navigate(const ScheduleScreen());
                  },
                  onCtaTap: (index) {
                    if (index == 0) {
                      _navigate(const TrackBusScreen());
                      return;
                    }
                    if (index == 1) {
                      _navigate(const ApplyCardScreen());
                      return;
                    }
                    _navigate(const ScheduleScreen());
                  },
                ),
                const SizedBox(height: 24),
                if (role == UserRole.driver)
                  _WideActionCard(
                    icon: Icons.route_rounded,
                    label: 'Driver Mode',
                    subtitle: 'Start sharing your live location',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    onTap: () => _navigate(const DriverScreen()),
                  ),
                if (role == UserRole.admin)
                  _WideActionCard(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Panel',
                    subtitle: 'Manage buses, routes & devices',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    onTap: () => _navigate(const AdminPanelScreen()),
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}

class _HeaderWeatherLine extends StatelessWidget {
  final Future<WeatherSnapshot?> weatherFuture;

  const _HeaderWeatherLine({required this.weatherFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherSnapshot?>(
      future: weatherFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            '🌤 --°C | Weather unavailable | DIU',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        final weather = snapshot.data!;
        final icon = WeatherService.iconForCondition(weather.condition);
        return Text(
          '$icon ${weather.temperatureC}°C | ${weather.condition} | ${weather.city}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_scale < 1 ? 0.1 : 0.16),
                    blurRadius: _scale < 1 ? 6 : 10,
                    offset: Offset(0, _scale < 1 ? 2 : 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _DashboardItem item;

  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.item.onTap != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.item.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _scale,
        child: Opacity(
          opacity: isInteractive ? 1 : 0.95,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.item.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_scale < 1 ? 0.1 : 0.14),
                  blurRadius: _scale < 1 ? 7 : 12,
                  offset: Offset(0, _scale < 1 ? 2 : 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.item.icon, color: Colors.white, size: 19),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselItem {
  final String title;
  final String subtitle;
  final String cta;
  final Gradient gradient;

  const _CarouselItem({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
  });
}

class _PromoCarousel extends StatefulWidget {
  final List<_CarouselItem> items;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onCardTap;
  final ValueChanged<int> onCtaTap;

  const _PromoCarousel({
    required this.items,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onCardTap,
    required this.onCtaTap,
  });

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  double _scale = 1;
  int? _pressedCtaIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: widget.controller,
            onPageChanged: widget.onPageChanged,
            itemCount: widget.items.length,
            itemBuilder: (_, index) {
              final item = widget.items[index];
              return GestureDetector(
                onTapDown: (_) => setState(() => _scale = 0.97),
                onTapCancel: () => setState(() => _scale = 1),
                onTapUp: (_) => setState(() => _scale = 1),
                onTap: () => widget.onCardTap(index),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  scale: _scale,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_scale < 1 ? 0.1 : 0.14),
                          blurRadius: _scale < 1 ? 8 : 14,
                          offset: Offset(0, _scale < 1 ? 2 : 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.86),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _pressedCtaIndex = index),
                          onTapCancel: () =>
                              setState(() => _pressedCtaIndex = null),
                          onTapUp: (_) =>
                              setState(() => _pressedCtaIndex = null),
                          onTap: () => widget.onCtaTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _pressedCtaIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.22),
                                width: _pressedCtaIndex == index ? 1.8 : 1.0,
                              ),
                              boxShadow: _pressedCtaIndex == index
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.25),
                                        blurRadius: 12,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: Text(
                              item.cta,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (index) {
            final active = widget.currentIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RoleBanner extends StatefulWidget {
  final UserRole role;
  const _RoleBanner({required this.role});

  @override
  State<_RoleBanner> createState() => _RoleBannerState();
}

class _RoleBannerState extends State<_RoleBanner> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final data = _bannerData[widget.role]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF475569);
    final gradientColors = isDark
        ? const [Color(0xFF3B1B2A), Color(0xFF43213A)]
        : const [Color(0xFFFEE2E2), Color(0xFFFCE7F3)];
    final borderColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFF2B6BE);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_scale < 1 ? 0.06 : 0.1),
                blurRadius: _scale < 1 ? 8 : 12,
                offset: Offset(0, _scale < 1 ? 2 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFEF4444).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data['icon'] as IconData,
                  color: const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['sub'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _bannerData = {
    UserRole.student: {
      'icon': Icons.school_rounded,
      'title': 'Student Mode',
      'sub': 'Track buses and plan your daily campus travel',
    },
    UserRole.driver: {
      'icon': Icons.drive_eta_rounded,
      'title': 'Driver Mode',
      'sub': 'Share live location and manage your assigned trip',
    },
    UserRole.admin: {
      'icon': Icons.admin_panel_settings_rounded,
      'title': 'Admin Mode',
      'sub': 'Manage buses, devices, and routes',
    },
  };
}

class _WideActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _WideActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_WideActionCard> createState() => _WideActionCardState();
}

class _WideActionCardState extends State<_WideActionCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_scale < 1 ? 0.1 : 0.16),
                blurRadius: _scale < 1 ? 8 : 12,
                offset: Offset(0, _scale < 1 ? 2 : 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoadLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderBusWidget extends StatelessWidget {
  const _HeaderBusWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 20,
      child: CustomPaint(
        painter: _HeaderBusPainter(),
      ),
    );
  }
}

class _HeaderBusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 3, size.width - 2, size.height - 7),
      const Radius.circular(6),
    );
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(bodyRect, bodyPaint);

    final windowPaint = Paint()..color = const Color(0xFFBFD7FF);
    final windowTop = 6.0;
    const windowHeight = 4.0;
    const windowWidth = 6.0;
    for (var i = 0; i < 4; i++) {
      final dx = 7.0 + (i * 8.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, windowTop, windowWidth, windowHeight),
          const Radius.circular(1.2),
        ),
        windowPaint,
      );
    }

    final doorPaint = Paint()..color = const Color(0xFF9FBDEB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 11, 8, 4, 7),
        const Radius.circular(1.2),
      ),
      doorPaint,
    );

    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(11, size.height - 2), 2.6, wheelPaint);
    canvas.drawCircle(Offset(size.width - 11, size.height - 2), 2.6, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
