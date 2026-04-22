import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

const String apiBase = 'https://liga-backend-f08y.onrender.com';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPL Chile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05080F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0D14),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = const [
    HomeScreen(),
    PlaceholderScreen(title: 'Calendario'),
    PlaceholderScreen(title: 'Tabla'),
    PlaceholderScreen(title: 'Jugadores'),
    PlaceholderScreen(title: 'Fotos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TPL Chile'),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tabla'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Fotos'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la portada');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeData.fromJson(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: futureHome,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text(
                    'Error cargando la portada',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futureHome = fetchHomeData();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final home = snapshot.data!;
        final nextRoundText = home.nextRound?.dateLabel ?? 'Por definir';
        final standings = home.standings;
        final matches = home.matches;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureHome = fetchHomeData();
            });
            await futureHome;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próxima jornada',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextRoundText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      home.nextRound == null
                          ? 'Aún no hay jornada futura disponible.'
                          : 'Jornada ${home.nextRound!.roundNumber}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cruces destacados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (matches.isEmpty)
                      const Text(
                        'No hay encuentros disponibles.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...matches.take(2).map(
                        (match) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${match.homeTeam} vs ${match.awayTeam}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sede ${match.venueClub}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  match.timeLabel,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tabla rápida',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (standings.isEmpty)
                      const Text(
                        'No hay tabla disponible.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...standings.take(4).map(
                        (team) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.amber.withOpacity(0.18),
                                child: Text(
                                  '${team.position}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  team.teamName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${team.totalPoints} pts',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

class HomeData {
  final List<StandingItem> standings;
  final List<MatchItem> matches;
  final NextRoundData? nextRound;

  HomeData({
    required this.standings,
    required this.matches,
    required this.nextRound,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final standingsJson = (json['standings'] as List<dynamic>? ?? []);
    final matchesJson = (json['matches'] as List<dynamic>? ?? []);
    final nextRoundJson = json['next_round'] as Map<String, dynamic>?;

    return HomeData(
      standings: standingsJson.map((e) => StandingItem.fromJson(e)).toList(),
      matches: matchesJson.map((e) => MatchItem.fromJson(e)).toList(),
      nextRound: nextRoundJson == null ? null : NextRoundData.fromJson(nextRoundJson),
    );
  }
}

class StandingItem {
  final int position;
  final String teamName;
  final int totalPoints;

  StandingItem({
    required this.position,
    required this.teamName,
    required this.totalPoints,
  });

  factory StandingItem.fromJson(Map<String, dynamic> json) {
    return StandingItem(
      position: json['position'] as int? ?? 0,
      teamName: json['team_name']?.toString() ?? '',
      totalPoints: json['total_points'] as int? ?? 0,
    );
  }
}

class MatchItem {
  final String homeTeam;
  final String awayTeam;
  final String venueClub;
  final DateTime? scheduledAt;

  MatchItem({
    required this.homeTeam,
    required this.awayTeam,
    required this.venueClub,
    required this.scheduledAt,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      homeTeam: json['home_team_name']?.toString() ?? '',
      awayTeam: json['away_team_name']?.toString() ?? '',
      venueClub: json['venue_club']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.tryParse(json['scheduled_at'].toString()),
    );
  }

  String get timeLabel {
    if (scheduledAt == null) return '--:--';
    final hour = scheduledAt!.hour.toString().padLeft(2, '0');
    final minute = scheduledAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class NextRoundData {
  final int? roundNumber;
  final DateTime? date;

  NextRoundData({
    required this.roundNumber,
    required this.date,
  });

  factory NextRoundData.fromJson(Map<String, dynamic> json) {
    return NextRoundData(
      roundNumber: json['round_number'] as int?,
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
    );
  }

  String get dateLabel {
    if (date == null) return 'Por definir';

    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];

    return '${date!.day} de ${months[date!.month]}';
  }
}
