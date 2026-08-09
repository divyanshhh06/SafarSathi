
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../modelss/bus.dart';
import '../modelss/route_model.dart';
import '../modelss/stop.dart';
import '../widget/bus_map.dart';
import '../widget/route_table.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedPage = 0;
  
  String _searchQuery = '';

  String _selectedLanguage = 'en';

  final List<Bus> _buses = [
    Bus(
      busId: 'BUS-101',
      routeId: 'R-01',
      position: const LatLng(23.2599, 77.4126),
      speedKmh: 34,
      bearing: 90,
      occupancy: OccupancyLevel.seatsAvailable,
    ),
    Bus(
      busId: 'BUS-102',
      routeId: 'R-02',
      position: const LatLng(23.2450, 77.4010),
      speedKmh: 27,
      bearing: 180,
      occupancy: OccupancyLevel.standingOnly,
    ),
    Bus(
      busId: 'BUS-103',
      routeId: 'R-03',
      position: const LatLng(23.2700, 77.4250),
      speedKmh: 16,
      bearing: 270,
      occupancy: OccupancyLevel.packed,
    ),
    Bus(
      busId: 'BUS-104',
      routeId: 'R-01',
      position: const LatLng(23.2500, 77.4350),
      speedKmh: 41,
      bearing: 0,
      occupancy: OccupancyLevel.seatsAvailable,
    ),
  ];

  final List<BusRoute> _routes = [
    const BusRoute(
      id: 'R-01',
      name: 'R-01',
      startPoint: 'Bhopal Terminal',
      endPoint: 'MP Nagar',
      stopIds: ['S-01', 'S-02', 'S-03', 'S-04'],
      status: 'Active',
      totalBuses: 8,
    ),
    const BusRoute(
      id: 'R-02',
      name: 'R-02',
      startPoint: 'Airport',
      endPoint: 'Habibganj',
      stopIds: ['S-05', 'S-06', 'S-07', 'S-08', 'S-09'],
      status: 'Active',
      totalBuses: 10,
    ),
    const BusRoute(
      id: 'R-03',
      name: 'R-03',
      startPoint: 'Kolar',
      endPoint: 'City Centre',
      stopIds: ['S-10', 'S-11', 'S-12'],
      status: 'Delayed',
      totalBuses: 6,
    ),
  ];

  // ignore: unused_field
  final List<BusStop> _stops = [
    const BusStop(
      id: 'S-01',
      name: 'Bhopal Terminal',
      position: LatLng(23.2599, 77.4126),
      address: 'Main Bus Terminal',
    ),
    const BusStop(
      id: 'S-02',
      name: 'Board Office',
      position: LatLng(23.2310, 77.4340),
      address: 'Board Office Square',
    ),
    const BusStop(
      id: 'S-03',
      name: 'MP Nagar',
      position: LatLng(23.2330, 77.4320),
      address: 'MP Nagar Zone 1',
    ),
  ];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted) {
          setState(() {
            
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<BusRoute> get _filteredRoutes {
    if (_searchQuery.trim().isEmpty) {
      return _routes;
    }

    final query = _searchQuery.toLowerCase();

    return _routes.where((route) {
      return route.id.toLowerCase().contains(query) ||
          route.name.toLowerCase().contains(query) ||
          route.startPoint.toLowerCase().contains(query) ||
          route.endPoint.toLowerCase().contains(query);
    }).toList();
  }

  // ignore: unused_element
  int get _activeBuses => _buses.length;

  // ignore: unused_element
  int get _delayedBuses {
    return _buses.where((bus) {
      return bus.speedKmh < 20;
    }).length;
  }

  // ignore: unused_element
  int get _offlineBuses {
    return 0;
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is ready for backend integration.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addRoute() {
    _showComingSoon('Add Route');
  }

  void _editRoute(BusRoute route) {
    _showComingSoon('Edit ${route.name}');
  }

  void _deleteRoute(BusRoute route) {
    _showComingSoon('Delete ${route.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _buildPageContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SafarSathi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _navItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),
          _navItem(
            icon: Icons.directions_bus_outlined,
            selectedIcon: Icons.directions_bus,
            title: 'Fleet',
            index: 1,
          ),
          _navItem(
            icon: Icons.alt_route_outlined,
            selectedIcon: Icons.alt_route,
            title: 'Routes',
            index: 2,
          ),
          _navItem(
            icon: Icons.schedule_outlined,
            selectedIcon: Icons.schedule,
            title: 'Schedules',
            index: 3,
          ),
          _navItem(
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            title: 'Analytics',
            index: 4,
          ),
          _navItem(
            icon: Icons.file_download_outlined,
            selectedIcon: Icons.file_download,
            title: 'GTFS Export',
            index: 5,
          ),
          _navItem(
            icon: Icons.network_check_outlined,
            selectedIcon: Icons.network_check,
            title: 'Network',
            index: 6,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.blue.shade700,
                    child: const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Administrator',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
  }) {
    final selected = _selectedPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: ListTile(
        selected: selected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          selected ? selectedIcon : icon,
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedPage = index;
          });
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Admin Control Center',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('System Online'),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedPage) {
      case 1:
        return _buildFleetPage();
      case 2:
        return _buildRoutesPage();
      case 3:
        return _buildSchedulesPage();
      case 4:
        return _buildAnalyticsPage();
      case 5:
        return _buildGtfsPage();
      case 6:
        return _buildNetworkPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'City Transport Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor your citywide bus network in real time.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 950) {
                return Column(
                  children: [
                    _buildMapCard(),
                    const SizedBox(height: 20),
                    _buildFleetStatusCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildMapCard(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFleetStatusCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          RouteTable(
            routes: _filteredRoutes,
            onAdd: _addRoute,
            onEdit: _editRoute,
            onDelete: _deleteRoute,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return Column(
            children: [
              _statCard(
                title: 'Total Fleet',
                value: '128',
                subtitle: 'Registered buses',
                icon: Icons.directions_bus,
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Active',
                value: '104',
                subtitle: 'Currently operating',
                icon: Icons.play_circle_outline,
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Delayed',
                value: '18',
                subtitle: 'Needs attention',
                icon: Icons.warning_amber_outlined,
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Offline',
                value: '6',
                subtitle: 'Not transmitting',
                icon: Icons.cloud_off_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Fleet',
                value: '128',
                subtitle: 'Registered buses',
                icon: Icons.directions_bus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                title: 'Active',
                value: '104',
                subtitle: 'Currently operating',
                icon: Icons.play_circle_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                title: 'Delayed',
                value: '18',
                subtitle: 'Needs attention',
                icon: Icons.warning_amber_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                title: 'Offline',
                value: '6',
                subtitle: 'Not transmitting',
                icon: Icons.cloud_off_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 470,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Live Fleet Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '● LIVE',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BusMap(
              buses: _buses,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatusCard() {
    return Container(
      height: 470,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _statusRow(
            'Active',
            104,
            Colors.green,
            0.81,
          ),
          const SizedBox(height: 18),
          _statusRow(
            'Delayed',
            18,
            Colors.orange,
            0.14,
          ),
          const SizedBox(height: 18),
          _statusRow(
            'Offline',
            6,
            Colors.red,
            0.05,
          ),
          const Divider(height: 40),
          const Text(
            'Current Activity',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _activityRow(
            Icons.directions_bus,
            'BUS-101',
            'R-01 • 34 km/h',
          ),
          _activityRow(
            Icons.warning_amber,
            'BUS-103',
            'R-03 • Delayed',
          ),
          _activityRow(
            Icons.directions_bus,
            'BUS-104',
            'R-01 • 41 km/h',
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    String label,
    int count,
    Color color,
    double progress,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _activityRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Fleet Management',
            'Monitor and manage the city bus fleet.',
            Icons.directions_bus,
          ),
          const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),
const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 24),

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    const Text(
      'Language:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(width: 8),
    DropdownButton<String>(
      value: _selectedLanguage,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'hi',
          child: Text('हिन्दी'),
        ),
        DropdownMenuItem(
          value: 'pa',
          child: Text('ਪੰਜਾਬੀ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 16),

_buildFleetTable(),

        ],
      ),
    );
  }

  Widget _buildFleetTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Bus')),
            DataColumn(label: Text('Route')),
            DataColumn(label: Text('Speed')),
            DataColumn(label: Text('Occupancy')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _buses.map((bus) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    bus.busId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(bus.routeId)),
                DataCell(
                  Text('${bus.speedKmh.toStringAsFixed(0)} km/h'),
                ),
                DataCell(
                  Text(bus.occupancy.label(_selectedLanguage)),
                ),
                DataCell(
                  _StatusBadge(
                    label: bus.speedKmh < 20 ? 'Delayed' : 'Active',
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          _showComingSoon('Edit ${bus.busId}');
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          _showComingSoon('Delete ${bus.busId}');
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoutesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Routes',
            'Manage city routes and their assigned buses.',
            Icons.alt_route,
          ),
          const SizedBox(height: 24),
          RouteTable(
            routes: _filteredRoutes,
            onAdd: _addRoute,
            onEdit: _editRoute,
            onDelete: _deleteRoute,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesPage() {
    final schedules = [
      ['R-01', 'BUS-101', '06:30 AM', '08:10 AM', 'On Time'],
      ['R-02', 'BUS-102', '07:00 AM', '08:45 AM', 'On Time'],
      ['R-03', 'BUS-103', '07:15 AM', '09:00 AM', 'Delayed'],
      ['R-01', 'BUS-104', '08:00 AM', '09:30 AM', 'On Time'],
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Schedules',
            'Monitor planned and active bus schedules.',
            Icons.schedule,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Route')),
                DataColumn(label: Text('Bus')),
                DataColumn(label: Text('Departure')),
                DataColumn(label: Text('Arrival')),
                DataColumn(label: Text('Status')),
              ],
              rows: schedules.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row[0])),
                    DataCell(Text(row[1])),
                    DataCell(Text(row[2])),
                    DataCell(Text(row[3])),
                    DataCell(
                      _StatusBadge(label: row[4]),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    final delayData = [22.0, 35.0, 18.0, 42.0, 30.0, 26.0, 15.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Analytics',
            'Understand delays and network performance.',
            Icons.analytics,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average Delay by Day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 260,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      delayData.length,
                      (index) {
                        final value = delayData[index];

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${value.toInt()} min',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: value * 4,
                                  constraints: const BoxConstraints(
                                    maxHeight: 190,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(days[index]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPeakHourCard(),
        ],
      ),
    );
  }

  Widget _buildPeakHourCard() {
    final hours = [
      ['06 AM', 30],
      ['08 AM', 85],
      ['10 AM', 55],
      ['12 PM', 40],
      ['02 PM', 45],
      ['04 PM', 70],
      ['06 PM', 95],
      ['08 PM', 72],
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak Hour Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ...hours.map(
            (hour) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(hour[0].toString()),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (hour[1] as int) / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 35,
                    child: Text('${hour[1]}%'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGtfsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'GTFS Export',
            'Prepare transport data for external transit systems.',
            Icons.file_download,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.folder_zip_outlined,
                  size: 48,
                ),
                const SizedBox(height: 18),
                const Text(
                  'General Transit Feed Specification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export routes, stops, schedules and trip information '
                  'in a GTFS-compatible format.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    _showComingSoon('GTFS Export');
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export GTFS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Network Monitor',
            'Monitor connectivity and data transmission health.',
            Icons.network_check,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _networkCard(
                  title: 'Download',
                  value: '82 Mbps',
                  percentage: 0.82,
                  icon: Icons.download,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _networkCard(
                  title: 'Upload',
                  value: '31 Mbps',
                  percentage: 0.31,
                  icon: Icons.upload,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _networkCard(
                  title: 'API Requests',
                  value: '1,284/min',
                  percentage: 0.64,
                  icon: Icons.api,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Network connection is healthy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Latency: 42 ms',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkCard({
    required String title,
    required String value,
    required double percentage,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool positive = label.toLowerCase() == 'active' ||
        label.toLowerCase() == 'on time';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: positive
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: positive ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}