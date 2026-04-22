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
    CalendarScreen(),
    StandingsScreen(),
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
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final home = snapshot.data!;
        final groupedMatches = groupMatchesByTie(home.matches);
        final featuredTies = groupedMatches.take(2).toList();

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
                      home.nextRound?.dateLabel ?? 'Por definir',
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
                    if (featuredTies.isEmpty)
                      const Text(
                        'No hay encuentros disponibles.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...featuredTies.map(
                        (tie) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TieCard(tie: tie),
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
                    if (home.standings.isEmpty)
                      const Text(
                        'No hay tabla disponible.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...home.standings.take(4).map(
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

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el calendario');
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
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final ties = groupMatchesByTie(snapshot.data!.matches);
        final rounds = groupTiesByRound(ties);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureHome = fetchHomeData();
            });
            await futureHome;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: rounds.entries.map((entry) {
              final roundNumber = entry.key;
              final roundTies = entry.value;
              final roundDate = roundTies.isNotEmpty ? roundTies.first.dateLabel : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jornada $roundNumber',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roundDate,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...roundTies.map(
                        (tie) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CalendarTieCard(tie: tie),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la tabla');
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
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final standings = snapshot.data!.standings;

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
                      'Tabla oficial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...standings.map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${team.wonGames} G • ${team.lostGames} P • Dif ${team.setsDiff}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${team.totalPoints} pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
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

class _TieCard extends StatelessWidget {
  final TieItem tie;

  const _TieCard({required this.tie});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  '${tie.homeTeam} vs ${tie.awayTeam}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sede ${tie.venueClub}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            tie.timeLabel,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTieCard extends StatelessWidget {
  final TieItem tie;

  const _CalendarTieCard({required this.tie});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          '${tie.homeTeam} vs ${tie.awayTeam}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Sede ${tie.venueClub} • ${tie.timeLabel}',
          style: const TextStyle(color: Colors.white70),
        ),
        children: tie.games.map((game) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    game.category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  game.timeLabel,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Error cargando datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeData {
  final List<StandingItem> standings;
  final List<MatchGameItem> matches;
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
      matches: matchesJson.map((e) => MatchGameItem.fromJson(e)).toList(),
      nextRound: nextRoundJson == null ? null : NextRoundData.fromJson(nextRoundJson),
    );
  }
}

class StandingItem {
  final int position;
  final String teamName;
  final int totalPoints;
  final int wonGames;
  final int lostGames;
  final int setsDiff;

  StandingItem({
    required this.position,
    required this.teamName,
    required this.totalPoints,
    required this.wonGames,
    required this.lostGames,
    required this.setsDiff,
  });

  factory StandingItem.fromJson(Map<String, dynamic> json) {
    return StandingItem(
      position: json['position'] as int? ?? 0,
      teamName: json['team_name']?.toString() ?? '',
      totalPoints: json['total_points'] as int? ?? 0,
      wonGames: json['won_games'] as int? ?? 0,
      lostGames: json['lost_games'] as int? ?? 0,
      setsDiff: json['sets_diff'] as int? ?? 0,
    );
  }
}

class MatchGameItem {
  final int matchId;
  final int roundNumber;
  final String homeTeam;
  final String awayTeam;
  final String venueClub;
  final String category;
  final DateTime? scheduledAt;

  MatchGameItem({
    required this.matchId,
    required this.roundNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.venueClub,
    required this.category,
    required this.scheduledAt,
  });

  factory MatchGameItem.fromJson(Map<String, dynamic> json) {
    return MatchGameItem(
      matchId: json['match_id'] as int? ?? 0,
      roundNumber: json['round_number'] as int? ?? 0,
      homeTeam: json['home_team_name']?.toString() ?? '',
      awayTeam: json['away_team_name']?.toString() ?? '',
      venueClub: json['venue_club']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
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

class TieItem {
  final int matchId;
  final int roundNumber;
  final String homeTeam;
  final String awayTeam;
  final String venueClub;
  final DateTime? scheduledAt;
  final List<MatchGameItem> games;

  TieItem({
    required this.matchId,
    required this.roundNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.venueClub,
    required this.scheduledAt,
    required this.games,
  });

  String get timeLabel {
    if (scheduledAt == null) return '--:--';
    final hour = scheduledAt!.hour.toString().padLeft(2, '0');
    final minute = scheduledAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get dateLabel {
    if (scheduledAt == null) return 'Por definir';

    const weekdays = [
      '',
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

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
      'diciembre',
    ];

    final weekday = weekdays[scheduledAt!.weekday];
    return '$weekday, ${scheduledAt!.day} de ${months[scheduledAt!.month]}';
  }
}

List<TieItem> groupMatchesByTie(List<MatchGameItem> matches) {
  final Map<int, List<MatchGameItem>> grouped = {};

  for (final match in matches) {
    grouped.putIfAbsent(match.matchId, () => []).add(match);
  }

  final ties = grouped.entries.map((entry) {
    final games = entry.value;
    games.sort((a, b) => a.category.compareTo(b.category));
    final first = games.first;

    return TieItem(
      matchId: first.matchId,
      roundNumber: first.roundNumber,
      homeTeam: first.homeTeam,
      awayTeam: first.awayTeam,
      venueClub: first.venueClub,
      scheduledAt: first.scheduledAt,
      games: games,
    );
  }).toList();

  ties.sort((a, b) {
    if (a.roundNumber != b.roundNumber) {
      return a.roundNumber.compareTo(b.roundNumber);
    }
    if (a.scheduledAt == null && b.scheduledAt == null) return 0;
    if (a.scheduledAt == null) return 1;
    if (b.scheduledAt == null) return -1;
    return a.scheduledAt!.compareTo(b.scheduledAt!);
  });

  return ties;
}

Map<int, List<TieItem>> groupTiesByRound(List<TieItem> ties) {
  final Map<int, List<TieItem>> grouped = {};

  for (final tie in ties) {
    grouped.putIfAbsent(tie.roundNumber, () => []).add(tie);
  }

  return grouped;
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
